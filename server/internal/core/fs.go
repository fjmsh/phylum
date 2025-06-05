package core

import (
	"context"
	"errors"
	"io"
	"strings"
	"time"

	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/crypt"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/sirupsen/logrus"
)

type ResourceBindConflictResolution int32

const (
	ResourceBindConflictResolutionError     = ResourceBindConflictResolution(0) // Error if exists
	ResourceBindConflictResolutionEnsure    = ResourceBindConflictResolution(1) // Error if type mismatch
	ResourceBindConflictResolutionRename    = ResourceBindConflictResolution(2) // Auto rename new resource
	ResourceBindConflictResolutionOverwrite = ResourceBindConflictResolution(3) // Delete existing resource only if type mismatch (preserves props)
	ResourceBindConflictResolutionDelete    = ResourceBindConflictResolution(4) // Delete existing resource before creating
)

var pg *goqu.Database
var _rootID uuid.UUID

func init() {
	pg = goqu.New("postgres", nil)
	goqu.SetDefaultPrepared(true)
}

type FileSystem interface {
	// ancestors.go
	GetAncestors(Resource) ([]ResourceAncestor, error)
	GetPath(Resource) (string, error)

	// filesystem.go
	WithDb(db.Handler) FileSystem
	WithPathRoot(pgtype.UUID) FileSystem
	RunInTx(func(FileSystem) error) error

	// create.go
	CreateResourceByPath(path string, id uuid.UUID, dir, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error)
	CreateResources(args []CreateResourcesParams) (int64, error)

	// find.go
	ResourceByID(uuid.UUID) (Resource, error)
	ResourceByPath(string) (Resource, error)
	ResourceByPathWithRoot(string) (Resource, error)
	FindVersion(Resource, uuid.UUID) (Version, error)

	// open.go
	OpenRead(start, length int, r Resource, versionID uuid.UUID) (io.ReadCloser, error)
	OpenWrite(r Resource, versionID uuid.UUID) (io.WriteCloser, error)
	ReadDir(r Resource, recursive bool) ([]Resource, error)
	ReadDirDeleted(r Resource, recursive, includeDeleted bool) ([]Resource, error)
	Walk(r Resource, depth int, fn func(Resource, string) error) error

	// copy_move.go
	Copy(r Resource, target string, id uuid.UUID, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, bool, error)
	Move(r Resource, target string, conflictResolution ResourceBindConflictResolution) (Resource, bool, error)

	// permissions.go
	// TODO: #users
	UpdatePermissions(r Resource, userID int32, permission Permission) (Resource, error)

	//publink.go
	CreatePublink(r Resource, id, password string, expires pgtype.Timestamp, accessLimit int) error
	ListPublinks(r Resource) ([]Publink, error)

	// search.go
	Search(query string, includeDeleted bool) ([]Resource, error)

	// shared.go
	SharedResources(excluded pgtype.UUID) ([]Resource, error)

	// disk_usage.go
	DiskUsage(r Resource) (DiskUsageInfo, error)

	// delete.go
	DeleteRecursive(r Resource, softDelete bool) (Resource, error)
	RestoreDeleted(r Resource, parentPathOrUUID string, name string, autoRename bool) (res Resource, count int, size int64, err error)

	// trash.go
	TrashList(cursor string, n uint) ([]Resource, string, error)
	TrashSummary() (int, int, error)
	TrashEmpty() (int, error)
}

func Open(ctx context.Context, userID int32, root pgtype.UUID, fullAccess bool) FileSystem {
	return filesystem{
		db:         db.Get(ctx),
		userID:     userID,
		pathRoot:   root,
		fullAccess: fullAccess,
	}
}

func OpenOmniscient(db db.Handler) FileSystem {
	return filesystem{
		db:         db,
		userID:     -1,
		pathRoot:   pgtype.UUID{Bytes: rootID(), Valid: true},
		fullAccess: true,
	}
}

func rootID() uuid.UUID {
	if _rootID == uuid.Nil {
		var err error
		_rootID, err = _readRootID(context.Background())
		if err != nil {
			logrus.Fatal("Could not read root ID: " + err.Error())
		}
	}
	return _rootID
}

func _readRootID(ctx context.Context) (uuid.UUID, error) {
	const q = "SELECT id FROM resources WHERE parent IS NULL"
	d := db.Get(ctx)
	row := d.QueryRow(q)
	var id uuid.UUID
	if err := row.Scan(&id); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			const createDir = "INSERT INTO resources(id, name, dir) VALUES ($1::UUID, '', TRUE)"
			id, _ := uuid.NewV7()
			_, err = d.Exec(createDir, id)
			return id, err
		}
		return uuid.Nil, err
	} else {
		return id, nil
	}
}

func OpenFromPublink(ctx context.Context, id string, password string) (ROFileSystem, error) {
	d := db.Get(ctx)
	link, err := getPublink(d, id)
	if err != nil {
		return nil, err
	}

	// check password
	if link.PasswordHash != "" {
		if password == "" {
			return nil, ErrInsufficientPermissions
		}
		if ok, err := crypt.Verify(password, link.PasswordHash); err != nil {
			return nil, err
		} else if !ok {
			return nil, ErrInsufficientPermissions
		}
	}

	// check expiration
	if link.Expires != 0 && time.UnixMilli(link.Expires).Before(time.Now()) {
		return nil, ErrResourceNotFound
	}

	// check max accesses
	if link.AccessLimit > 0 && link.AccessLimit <= link.Accessed {
		return nil, ErrResourceNotFound
	}

	const q = "UPDATE publinks SET accessed = accessed + 1 WHERE id = $1"
	if _, err := d.Exec(q, link.ID); err != nil {
		return nil, err
	}

	return roFilesystem{f: filesystem{
		db:         d,
		pathRoot:   pgtype.UUID{Bytes: link.Root, Valid: true},
		fullAccess: true, // TODO: #permissions Replace with permissions int
	}}, nil
}

func getPublink(d db.Handler, id string) (Publink, error) {
	q := "SELECT * FROM publinks p WHERE id = $1::TEXT"
	if rows, err := d.Query(q, id); err != nil {
		return Publink{}, err
	} else if link, err := pgx.CollectExactlyOneRow(rows, scanPublink); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrParentNotFound
		}
		return Publink{}, err
	} else {
		return link, nil
	}
}

func CheckNameInvalid(s string) bool {
	return s == "" || s == "." || s == ".." || strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}
