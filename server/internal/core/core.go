package core

import (
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var pg *goqu.Database
var userConfig UserConfig
var fsPathRoot pgtype.UUID

func Initialize(db db.Handler, cfg Config) error {
	pg = goqu.New("postgres", nil)
	goqu.SetDefaultPrepared(true)

	if rootID, err := insertOrSelectRootID(db); err != nil {
		return errors.New("failed to read filesystem root")
	} else {
		fsPathRoot = pgtype.UUID{Bytes: rootID, Valid: true}
	}
	userConfig = cfg.User

	return nil
}

// filesystem_readonly.go
type ReadFileSystem interface {
	ResourceByPath(string) (Resource, error)
	ReadDir(Resource, bool) ([]Resource, error)
	GetVersion(Resource, uuid.UUID) (Version, error)
	Walk(Resource, int, func(Resource, string) error) error
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
