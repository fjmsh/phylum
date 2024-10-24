package fs

import (
	"context"
	"strings"

	"github.com/google/uuid"
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

	// find.go
	ResourceByID(id uuid.UUID) (Resource, error)
	ResourceByPath(path string) (Resource, error)
	ResourceByPathOrUUID(pathOrUUID string) (Resource, error)

	// copy_move.go
	Move(r Resource, target string, overwrite bool) (Resource, bool, error)
	Copy(r Resource, target string, id uuid.UUID, recursive, overwrite bool) (Resource, bool, error)
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
