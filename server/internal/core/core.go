package core

import (
	"context"
	"errors"
	"io"

	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
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

func OpenFileSystem(ctx context.Context, userID int32, root pgtype.UUID, fullAccess bool) FileSystem {
	return filesystem{
		db:         db.Get(ctx),
		userID:     userID,
		pathRoot:   root,
		fullAccess: fullAccess,
	}
}

func (u User) OpenFileSystem(ctx context.Context) FileSystem {
	return OpenFileSystem(ctx, u.ID, u.Home, u.Permissions&PermissionFilesAll != 0)
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
