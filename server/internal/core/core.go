package core

import (
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/doug-martin/goqu/v9"
	_ "github.com/doug-martin/goqu/v9/dialect/postgres"
	"github.com/google/uuid"
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
