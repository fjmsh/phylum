package core

import (
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/rs/zerolog/log"
)

type FileSystem struct {
	db       db.Handler
	user     User
	pathRoot pgtype.UUID
}

type txFileSystem struct {
	*FileSystem
	db db.TxHandler
}

func OpenFileSystem(db db.Handler, user User, pathRoot pgtype.UUID) *FileSystem {
	return &FileSystem{
		db:       db,
		user:     user,
		pathRoot: pathRoot,
	}
}

func (u User) OpenFileSystem(db db.Handler) *FileSystem {
	return OpenFileSystem(db, u, u.Home)
}

func OpenOmniscient(db db.Handler) *FileSystem {
	return openOmniscient(db)
}
func openOmniscient(db db.Handler) *FileSystem {
	return &FileSystem{
		db:       db,
		user:     User{ID: -1, Permissions: -1},
		pathRoot: pgtype.UUID{Bytes: rootID(db), Valid: true},
	}
}

func openOmniscientTx(db db.TxHandler) txFileSystem {
	return txFileSystem{
		FileSystem: &FileSystem{
			db:       db,
			user:     User{ID: -1, Permissions: -1},
			pathRoot: pgtype.UUID{Bytes: rootID(db), Valid: true},
		},
		db: db,
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
		db:       f.db,
		user:     f.user,
		pathRoot: pathRoot,
	}
}

func (f *FileSystem) PathRoot() pgtype.UUID {
	return f.pathRoot
}

func rootID(db db.Handler) uuid.UUID {
	if _rootID == uuid.Nil {
		var err error
		_rootID, err = _readRootID(db)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to read filesystem root")
		}
	}
	return _rootID
}

func _readRootID(d db.Handler) (uuid.UUID, error) {
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
