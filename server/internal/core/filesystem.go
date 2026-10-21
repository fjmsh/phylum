package core

import (
	"encoding/json"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type FileSystem struct {
	db                 db.Handler
	pathRoot           pgtype.UUID
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

func (f FileSystem) IsRoot(root uuid.UUID) bool {
	return f.pathRoot.Valid && f.pathRoot.Bytes == root
}

func OpenFileSystem(db db.Handler, pathRoot pgtype.UUID, userID int32, userPrivileges UserPrivileges, scopes []string) *FileSystem {
	allResourcesScope, scopedResources := parseScopedResources(scopes)
	return &FileSystem{
		db:                 db,
		pathRoot:           pathRoot,
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
	return OpenFileSystem(db, fsPathRoot, -1, []UserPrivilege{UserPrivilegeSU}, []string{"*"})
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
		db:                 f.db,
		pathRoot:           pathRoot,
		userID:             f.userID,
		userFilesPrivilege: f.userFilesPrivilege,
		allResourcesScope:  f.allResourcesScope,
		scopedResources:    f.scopedResources,
	}
}

func (f *FileSystem) checkPermission(r Resource, p ResourcePermission) (ResourcePermission, error) {
	// TODO: Take into account scopes for all ancestors
	scopePermissions := f.allResourcesScope | f.scopedResources[f.pathRoot.Bytes] | f.scopedResources[r.id]
	if scopePermissions&p != p {
		return 0, ErrInsufficientPermissions
	}
	p = p & (^f.userFilesPrivilege)

	if permissions, err := permissionFromJson(r.permissions); err != nil {
		return 0, err
	} else {
		up := permissions[f.userID]
		if (up|f.userFilesPrivilege)&p != p {
			return 0, ErrInsufficientPermissions
		} else {
			return up | f.userFilesPrivilege, nil
		}
	}
}

func permissionFromJson(j []byte) (map[int32]ResourcePermission, error) {
	if j == nil {
		return nil, nil
	}
	p := make(map[int32]ResourcePermission)
	err := json.Unmarshal(j, &p)
	if err != nil {
		return nil, err
	}
	return p, nil
}
