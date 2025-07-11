package core

import (
	"errors"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
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
		scopePermissions: GetScopePermissions(scopes, pathRoot.Bytes),
	}
}

func GetScopePermissions(scopes []string, id uuid.UUID) (p Permission) {
	idString := id.String()
	for _, s := range scopes {
		if s == "" || s == "*" {
			return PermissionSU
		}

		parts := strings.Split(s, ":")
		if parts[0] == "*" || parts[0] == idString {
			if len(parts) == 0 || parts[1] == "*" {
				return PermissionSU
			} else if parts[1] == "read" {
				p |= PermissionRead
			} else if parts[1] == "write" {
				p |= PermissionWrite
			} else if parts[1] == "share" {
				p |= PermissionShare
			}
		}
	}
	return p
}

func OpenOmniscient(db db.Handler) *FileSystem {
	return &FileSystem{
		db:               db,
		pathRoot:         fsPathRoot,
		userID:           -1,
		userPermissions:  -1,
		scopes:           []string{"*"},
		scopePermissions: -1,
	}
}

func openOmniscientTx(db db.TxHandler) txFileSystem {
	return txFileSystem{
		FileSystem: OpenOmniscient(db),
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
		scopePermissions: GetScopePermissions(f.scopes, pathRoot.Bytes),
	}
}

func insertOrSelectRootID(d db.Handler) (uuid.UUID, error) {
	const q = "SELECT id FROM resources WHERE parent IS NULL"
	row := d.QueryRow(q)
	var id uuid.UUID
	if err := row.Scan(&id); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			const createDir = "INSERT INTO resources(id, name, dir) VALUES ($1::UUID, '', TRUE)"
			id, _ := uuid.NewV7()
			if err := d.RunInTx(func(db db.TxHandler) error {
				_, err = db.Exec(createDir, id)
				return err
			}); err != nil {
				return uuid.Nil, err
			}
			return id, nil
		}
		return uuid.Nil, err
	} else {
		return id, nil
	}
}
