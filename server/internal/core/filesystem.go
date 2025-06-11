package core

import (
	"context"
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/sirupsen/logrus"
)

type filesystem struct {
	db       db.Handler
	user     User
	pathRoot pgtype.UUID
}

func OpenFileSystem(ctx context.Context, user User, pathRoot pgtype.UUID) FileSystem {
	return filesystem{
		db:       db.Get(ctx),
		user:     user,
		pathRoot: pathRoot,
	}
}

func (u User) OpenFileSystem(ctx context.Context) FileSystem {
	return OpenFileSystem(ctx, u, u.Home)
}

func OpenOmniscient(db db.Handler) FileSystem {
	return openOmniscient(db)
}
func openOmniscient(db db.Handler) filesystem {
	return filesystem{
		db:       db,
		user:     User{ID: -1, Permissions: -1},
		pathRoot: pgtype.UUID{Bytes: rootID(), Valid: true},
	}
}

func (f filesystem) WithDb(db db.Handler) FileSystem {
	return f.withDb(db)
}

func (f filesystem) withDb(db db.Handler) filesystem {
	return filesystem{
		db:       db,
		user:     f.user,
		pathRoot: f.pathRoot,
	}
}

func (f filesystem) WithPathRoot(pathRoot pgtype.UUID) FileSystem {
	return f.withPathRoot(pathRoot)
}

func (f filesystem) withPathRoot(pathRoot pgtype.UUID) filesystem {
	return filesystem{
		db:       f.db,
		user:     f.user,
		pathRoot: pathRoot,
	}
}

func (f filesystem) RunInTx(fn func(FileSystem) error) error {
	return f.db.RunInTx(func(db db.Handler) error {
		return fn(f.WithDb(db))
	})
}

func (f filesystem) runInTx(fn func(filesystem) error) error {
	return f.db.RunInTx(func(db db.Handler) error {
		return fn(f.withDb(db))
	})
}

func rootID() uuid.UUID {
	if _rootID == uuid.Nil {
		var err error
		_rootID, err = _readRootID(context.Background())
		if err != nil {
			logrus.Fatal("Could not read root ID: " + err.Error())
		}
	}
	return _rootID
}

func _readRootID(ctx context.Context) (uuid.UUID, error) {
	const q = "SELECT id FROM resources WHERE parent IS NULL"
	d := db.Get(ctx)
	row := d.QueryRow(q)
	var id uuid.UUID
	if err := row.Scan(&id); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			const createDir = "INSERT INTO resources(id, name, dir) VALUES ($1::UUID, '', TRUE)"
			id, _ := uuid.NewV7()
			_, err = d.Exec(createDir, id)
			return id, err
		}
		return uuid.Nil, err
	} else {
		return id, nil
	}
}
