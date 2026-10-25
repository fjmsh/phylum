package core

import (
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type FileSystem struct {
	db                 db.Handler
	fsRoot             uuid.UUID
	userHome           pgtype.UUID
	userID             int32
	userFilesPrivilege ResourcePermission
	allResourcesScope  ResourcePermission
	scopedResources    map[uuid.UUID]ResourcePermission
}

type txFileSystem struct {
	*FileSystem
	db db.TxHandler
}

func (f FileSystem) IsUser(userID int32) bool {
	return f.userID == userID
}

func OpenFileSystem(db db.Handler, fsRoot uuid.UUID, userHome pgtype.UUID, userID int32, userPrivileges UserPrivileges, scopes []string) *FileSystem {
	if fsRoot == uuid.Nil {
		fsRoot = fsPathRoot
	}
	allResourcesScope, scopedResources := parseScopedResources(scopes)
	return &FileSystem{
		db:                 db,
		fsRoot:             fsRoot,
		userHome:           userHome,
		userID:             userID,
		userFilesPrivilege: userPrivileges.GetFilesPermissions(),
		allResourcesScope:  allResourcesScope,
		scopedResources:    scopedResources,
	}
}

func parseScopedResources(scopes []string) (ResourcePermission, map[uuid.UUID]ResourcePermission) {
	var allResourcesScope ResourcePermission
	scopedResources := make(map[uuid.UUID]ResourcePermission)
	for _, s := range scopes {
		parts := strings.Split(s, ":")
		var p ResourcePermission
		switch parts[0] {
		case "*", "":
			p = ResourcePermissionsAll
		case "read":
			p = ResourcePermissionRead
		case "write":
			p = ResourcePermissionRead | ResourcePermissionWrite
		case "share":
			p = ResourcePermissionRead | ResourcePermissionWrite | ResourcePermissionShare
		}
		if len(parts) == 1 || len(parts) == 2 && parts[1] == "*" {
			allResourcesScope = allResourcesScope | p
		} else if len(parts) == 2 {
			if uuid, err := uuid.Parse(parts[1]); err == nil {
				scopedResources[uuid] = scopedResources[uuid] | p
			}
		}
	}
	return allResourcesScope, scopedResources
}

func OpenSUFileSystem(db db.Handler) *FileSystem {
	return OpenFileSystem(db, fsPathRoot, pgtype.UUID{}, -1, []UserPrivilege{UserPrivilegeSU}, []string{"*"})
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
