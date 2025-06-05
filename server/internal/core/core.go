package core

import (
	"io"

	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/db"
)

var Cfg Config
var pg *goqu.Database
var _rootID uuid.UUID

func init() {
	pg = goqu.New("postgres", nil)
	goqu.SetDefaultPrepared(true)
}

type FileSystem interface {
	// filesystem.go
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
	FindVersion(Resource, uuid.UUID) (Version, error)

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

type UserManager interface {
	// user_manager.go
	CreateUser(email, name string, noCreateHome bool) (User, error)
	ListUsers(since int64) ([]User, error)
	UserByEmail(email string) (User, error)
	UserHome(email string) (pgtype.UUID, error)

	// user_auth.go
	VerifyUserPassword(email, password string) (User, error)
	CreateAccessToken(user User) (string, error)
	ReadAccessToken(accessToken string) (User, error)
	CreateResetToken(user User) (string, error)
	ResetUserPassword(user User, token, password string) error

	// update.go
	UpdateUserHome(user User, home pgtype.UUID) error
	UpdateUserName(user User, name string) error
	UpdateUserPassword(user User, password string) error
	GrantUserPermissions(user User, permissions Permissions) error
	RevokeUserPermissions(user User, permissions Permissions) error

	// user_bookmarks.go
	AddBookmark(u User, resource Resource, name string) (Bookmark, error)
	RemoveBookmark(u User, id uuid.UUID) error
	ListBookmarks(u User, since int64) ([]Bookmark, error)
}
