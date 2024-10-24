package fs

import (
	"context"
	"io"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/api/serve"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type FileSystem interface {
	// filesystem.go
	RootID() uuid.UUID
	WithRoot(uuid.UUID) FileSystem
	WithDb(db *db.DbHandler) FileSystem
	RunInTx(fn func(FileSystem) error) error

	// create.go
	CreateResourceByPath(path string, dir, recursive bool) (Resource, error)
	CreateMemberResource(r Resource, id uuid.UUID, name string, dir bool) (Resource, error)

	// find.go
	ResourceByID(id uuid.UUID) (Resource, error)
	ResourceByPath(path string) (Resource, error)
	ResourceByPathOrUUID(pathOrUUID string) (Resource, error)

	// open.go
	OpenRead(r serve.Resource, start, length int64) (io.ReadCloser, error)
	OpenWrite(r Resource) (io.WriteCloser, error)
	ReadDir(r serve.Resource, recursive bool) ([]serve.Resource, error)
	ProcessResources(r serve.Resource, depth int, fn func(serve.Resource) error) error

	// delete.go
	DeleteChildRecursive(r Resource, name string, hardDelete bool) error
	DeleteRecursive(r Resource, hardDelete bool) error

	// copy_move.go
	Move(r Resource, target string, overwrite bool) (Resource, bool, error)
	Copy(r Resource, target string, id uuid.UUID, recursive, overwrite bool) (Resource, bool, error)

	// update.go
	UpdatePermissions(r Resource, username string, permission Permission) (Resource, error)

	// disk_usage.go
	DiskUsage(r Resource) (DiskUsageInfo, error)
}

func Open(ctx context.Context, username string, root uuid.UUID) FileSystem {
	return filesystem{
		ctx:      ctx,
		db:       db.Get(),
		cs:       storage.Get(),
		username: username,
		rootID:   root,
	}
}

func CheckNameInvalid(s string) bool {
	return strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}
