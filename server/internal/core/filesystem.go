package core

import (
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/sirupsen/logrus"
)

type fileSystem struct {
	db       db.Handler
	user     User
	pathRoot pgtype.UUID
}

type txFileSystem struct {
	fileSystem
	db db.TxHandler
}

func OpenFileSystem(db db.Handler, user User, pathRoot pgtype.UUID) FileSystem {
	return fileSystem{
		db:       db,
		user:     user,
		pathRoot: pathRoot,
	}
}

func (u User) OpenFileSystem(db db.Handler) FileSystem {
	return OpenFileSystem(db, u, u.Home)
}

func OpenOmniscient(db db.Handler) FileSystem {
	return openOmniscient(db)
}
func openOmniscient(db db.Handler) fileSystem {
	return fileSystem{
		db:       db,
		user:     User{ID: -1, Permissions: -1},
		pathRoot: pgtype.UUID{Bytes: rootID(db), Valid: true},
	}
}

func openOmniscientTx(db db.TxHandler) txFileSystem {
	return txFileSystem{
		fileSystem: fileSystem{
			db:       db,
			user:     User{ID: -1, Permissions: -1},
			pathRoot: pgtype.UUID{Bytes: rootID(db), Valid: true},
		},
		db: db,
	}
}

func (f fileSystem) runInTx(fn func(f txFileSystem) error) error {
	return f.db.RunInTx(func(tx db.TxHandler) error {
		return fn(txFileSystem{
			fileSystem: f,
			db:         tx,
		})
	})
}

func (f fileSystem) withPathRoot(pathRoot pgtype.UUID) fileSystem {
	return fileSystem{
		db:       f.db,
		user:     f.user,
		pathRoot: pathRoot,
	}
}

func rootID(db db.Handler) uuid.UUID {
	if _rootID == uuid.Nil {
		var err error
		_rootID, err = _readRootID(db)
		if err != nil {
			logrus.Fatal("Could not read root ID: " + err.Error())
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
			_, err = d.ExecNoTx(createDir, id)
			return id, err
		}
		return uuid.Nil, err
	} else {
		return id, nil
	}
}
