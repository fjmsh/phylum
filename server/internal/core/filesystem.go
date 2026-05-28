package core

import (
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type FileSystem struct {
	db               db.Handler
	pathRoot         pgtype.UUID
	userID           int32
	userPermissions  UserPermissions
	scopes           []string
	scopePermissions Permission
}

type txFileSystem struct {
	*FileSystem
	db db.TxHandler
}

func OpenFileSystem(db db.Handler, pathRoot pgtype.UUID, userID int32, userPermissions UserPermissions, scopes []string) *FileSystem {
	return &FileSystem{
		db:               db,
		pathRoot:         pathRoot,
		userID:           userID,
		userPermissions:  userPermissions,
		scopes:           scopes,
		scopePermissions: getScopePermissions(scopes, pathRoot.Bytes),
	}
}

func getScopePermissions(scopes []string, id uuid.UUID) (p Permission) {
	idString := id.String()
	for _, s := range scopes {
		parts := strings.Split(s, ":")
		if len(parts) == 1 || parts[1] == idString || parts[1] == "*" {
			switch parts[0] {
			case "*", "":
				p = PermissionAll
			case "read":
				p = PermissionRead
			case "write":
				p = PermissionRead | PermissionWrite
			case "share":
				p = PermissionRead | PermissionWrite | PermissionShare
			}
		}
	}
	return p
}

func OpenSUFileSystem(db db.Handler) *FileSystem {
	return &FileSystem{
		db:               db,
		pathRoot:         fsPathRoot,
		userID:           -1,
		userPermissions:  []UserPermission{UserPermissionSU},
		scopes:           []string{"*"},
		scopePermissions: -1,
	}
}

func openSUFileSystemTx(db db.TxHandler) txFileSystem {
	return txFileSystem{
		FileSystem: OpenSUFileSystem(db),
		db:         db,
	}
}

func (f *FileSystem) runInTx(fn func(f txFileSystem) error) error {
	return f.db.RunInTx(func(tx db.TxHandler) error {
		return fn(txFileSystem{
			FileSystem: f,
			db:         tx,
		})
	})
}

func (f *FileSystem) withPathRoot(pathRoot pgtype.UUID) *FileSystem {
	return &FileSystem{
		db:               f.db,
		pathRoot:         pathRoot,
		userID:           f.userID,
		userPermissions:  f.userPermissions,
		scopes:           f.scopes,
		scopePermissions: getScopePermissions(f.scopes, pathRoot.Bytes),
	}
}

func (f *FileSystem) checkPermission(r Resource, p Permission) error {
	if p|PermissionRead != 0 && f.userPermissions.HasPermission(UserPermissionFilesRead) {
		p = p ^ PermissionRead
	}
	if p|PermissionWrite != 0 && f.userPermissions.HasPermission(UserPermissionFilesWrite) {
		p = p ^ PermissionWrite
	}
	if p|PermissionShare != 0 && f.userPermissions.HasPermission(UserPermissionFilesShare) {
		p = p ^ PermissionShare
	}

	if up, err := readPermissionFromJson(r.permissions, f.userID); err != nil {
		return err
	} else if (up&p != p) || (f.scopePermissions&p != p) {
		return ErrInsufficientPermissions
	}
	return nil
}
