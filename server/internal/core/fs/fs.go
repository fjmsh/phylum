package fs

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

type ResourceBindConflictResolution int32

const (
	ResourceBindConflictResolutionError     = 0 // Error if exists
	ResourceBindConflictResolutionEnsure    = 1 // Error if type mismatch
	ResourceBindConflictResolutionRename    = 2 // Auto rename new resource
	ResourceBindConflictResolutionOverwrite = 3 // Delete existing resource only if type mismatch (preserves props)
	ResourceBindConflictResolutionDelete    = 4 // Delete existing resource before creating
)

var pg *goqu.Database

func init() {
	pg = goqu.New("postgres", nil)
	goqu.SetDefaultPrepared(true)
}

type FileSystem interface {
	// filesystem.go
	RootID() uuid.UUID
	WithRoot(uuid.UUID) FileSystem
	WithDb(db *db.Handler) FileSystem
	RunInTx(fn func(FileSystem) error) error

	// create.go
	CreateResourceByPath(path string, dir, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, error)
	CreateResources(args []CreateResourcesParams) (int64, error)

	// find.go
	ResourceByID(id uuid.UUID) (Resource, error)
	ResourceByPath(path string) (Resource, error)
	ResourceByPathOrUUID(pathOrUUID string) (Resource, error)

	// search.go
	Search(query string, includeDeleted bool) ([]Resource, error)

	// shared.go
	SharedResources() ([]Resource, error)

	// trash.go
	TrashList(cursor string, n uint) ([]Resource, string, error)
	TrashSummary() (int, int, error)
	TrashEmpty() (int, error)
}

func Open(ctx context.Context, username string, root uuid.UUID, fullAccess bool) FileSystem {
	return filesystem{
		ctx:        ctx,
		db:         db.Get(),
		cs:         storage.Get(),
		username:   username,
		rootID:     root,
		fullAccess: fullAccess,
	}
}

func OpenFromPublink(ctx context.Context, name string, password string, path string) (Resource, error) {
	d := db.Get()
	link, err := getPublink(d, ctx, name)
	if err != nil {
		return Resource{}, err
	}

	// check password
	if link.PasswordHash != "" {
		if password == "" {
			return Resource{}, ErrInsufficientPermissions
		}
		if ok, err := crypt.VerifyPassword(password, link.PasswordHash); err != nil {
			return Resource{}, err
		} else if !ok {
			return Resource{}, ErrInsufficientPermissions
		}
	}

	// check expiration
	if link.Expires.Valid && link.Expires.Time.Before(time.Now()) {
		return Resource{}, ErrResourceNotFound
	}

	// check max accesses
	if link.MaxAccesses > 0 && link.MaxAccesses <= link.Accessed {
		return Resource{}, ErrResourceNotFound
	}

	const q = "UPDATE publinks SET accessed = accessed + 1 WHERE id = $1"
	if _, err := d.Exec(ctx, q, link.ID); err != nil {
		return Resource{}, err
	}

	f := filesystem{
		ctx:        ctx,
		db:         d,
		cs:         storage.Get(),
		rootID:     link.Root,
		fullAccess: true, // TODO: #permissions Replace with permissions int
	}

	return f.ResourceByPath(path)
}

func getPublink(d *db.Handler, ctx context.Context, name string) (Publink, error) {
	q := "SELECT FROM publinks p WHERE name = $1::TEXT AND deleted IS NULL"
	if rows, err := d.Query(ctx, q, name); err != nil {
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
	return strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}
