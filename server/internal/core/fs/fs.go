package fs

import (
	"context"
	"io"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type FileSystem interface {
	// filesystem.go
	RootID() uuid.UUID
	WithDb(db *db.DbHandler) FileSystem
	RunInTx(fn func(FileSystem) error) error

	// create.go
	CreateResourceByPath(path string, dir bool) (Resource, error)
	CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error)

	// find.go
	ResourceByID(id uuid.UUID) (Resource, error)
	ResourceByPath(path string) (Resource, error)
	ResourceByPathOrUUID(pathOrUUID string) (Resource, error)

	// open.go
	OpenRead(r Resource, start, length int64) (io.ReadCloser, error)
	OpenWrite(r Resource) (io.WriteCloser, error)
	ReadDir(r Resource, recursive bool) ([]Resource, error)
	ProcessResources(r Resource, depth int, fn func(Resource) error) error

	// delete.go
	DeleteChildRecursive(r Resource, name string, hardDelete bool) error
	DeleteRecursive(r Resource, hardDelete bool) error

	// copy_move.go
	Move(r Resource, target string, overwrite bool) (Resource, bool, error)
	Copy(r Resource, target string, id uuid.UUID, recursive, overwrite bool) (Resource, bool, error)

	// update.go
	UpdateName(r Resource, name string) (Resource, error)
	UpdatePermissions(r Resource, username string, permission Permission) (Resource, error)

	// disk_usage.go
	DiskUsage(r Resource) (DiskUsageInfo, error)
}

func OpenFileSystem(dbh *db.DbHandler, ctx context.Context, cs storage.Storage, username string, rootID uuid.UUID) FileSystem {
	return filesystem{
		db:       dbh,
		ctx:      ctx,
		cs:       cs,
		rootID:   rootID,
		username: username,
	}
}

func checkNameInvalid(s string) bool {
	return strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}
