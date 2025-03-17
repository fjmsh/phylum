package fs

import (
	"context"
	"strings"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
)

type ResourceBindConflictResolution int32

const (
	ResourceBindConflictResolutionError     = 0 // Error if exists
	ResourceBindConflictResolutionEnsure    = 1 // Error if type mismatch
	ResourceBindConflictResolutionRename    = 2 // Auto rename new resource
	ResourceBindConflictResolutionOverwrite = 3 // Delete existing resource only if type mismatch (preserves props)
	ResourceBindConflictResolutionDelete    = 4 // Delete existing resource before creating
)

type FileSystem interface {
	// filesystem.go
	RootID() uuid.UUID
	WithRoot(uuid.UUID) FileSystem
	WithDb(db *db.DbHandler) FileSystem
	RunInTx(fn func(FileSystem) error) error

	// create.go
	CreateResourceByPath(path string, dir, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, error)

	// find.go
	ResourceByID(id uuid.UUID) (Resource, error)
	ResourceByPath(path string) (Resource, error)
	ResourceByPathOrUUID(pathOrUUID string) (Resource, error)

	// trash.go
	TrashList(cursor string, n int) ([]Resource, string, error)
	TrashSummary() (int, int, error)
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

func CheckNameInvalid(s string) bool {
	return strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}
