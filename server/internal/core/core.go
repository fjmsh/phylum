package core

import (
	"io"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

var Cfg Config
var pg *goqu.Database
var _rootID uuid.UUID

func init() {
	pg = goqu.New("postgres", nil)
	goqu.SetDefaultPrepared(true)
}

// filesystem.go
type FileSystem interface {
	WithDb(db.Handler) FileSystem
	WithPathRoot(pgtype.UUID) FileSystem
	RunInTx(func(FileSystem) error) error

	// resource_create.go
	CreateResourceByPath(path string, id uuid.UUID, dir, createParents bool, conflictResolution ResourceBindConflictResolution) (Resource, error)
	CreateResources(args []CreateResourcesParams) (int64, error)

	// resource_locate.go
	ResourceByID(uuid.UUID) (Resource, error)
	ResourceByPath(string) (Resource, error)
	ResourceByPathWithRoot(string) (Resource, error)

	// resource_versions.go
	GetVersion(Resource, uuid.UUID) (Version, error)
	GetAllVersions(Resource) ([]Version, error)

	// resource_ancestors.go
	GetAncestors(Resource) ([]ResourceAncestor, error)
	GetPath(Resource) (string, error)

	// resource_open.go
	OpenWrite(r Resource, versionID uuid.UUID) (io.WriteCloser, error)
	ReadDir(r Resource, recursive bool) ([]Resource, error)
	ReadDirDeleted(r Resource, recursive, includeDeleted bool) ([]Resource, error)
	Walk(r Resource, depth int, fn func(Resource, string) error) error

	// resource_copy_move.go
	Copy(r Resource, target string, id uuid.UUID, recursive bool, conflictResolution ResourceBindConflictResolution) (Resource, bool, error)
	Move(r Resource, target string, conflictResolution ResourceBindConflictResolution) (Resource, bool, error)

	// resource_permissions.go
	UpdatePermissions(r Resource, user User, permission Permission) (Resource, error)

	// resource_publink.go
	CreatePublink(r Resource, id, password string, expires pgtype.Timestamp, accessLimit int) error
	ListPublinks(r Resource) ([]Publink, error)

	// search.go
	Search(query string, includeDeleted bool) ([]Resource, error)

	// disk_usage.go
	DiskUsage(r Resource) (DiskUsageInfo, error)

	// delete.go
	Delete(r Resource, softDelete bool) (Resource, error)
	RestoreDeleted(r Resource, parentPathOrUUID string, name string, autoRename bool) (res Resource, count int, size int64, err error)

	// trash.go
	TrashList(cursor string, n uint) ([]Resource, string, error)
	TrashSummary() (int, int, error)
	TrashEmpty() (int, error)
}

// filesystem_readonly.go
type ReadFileSystem interface {
	ResourceByPath(string) (Resource, error)
	ReadDir(Resource, bool) ([]Resource, error)
	GetVersion(Resource, uuid.UUID) (Version, error)
	Walk(Resource, int, func(Resource, string) error) error
}

// user_manager.go
type UserManager interface {
}
