package db

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shroff/phylum/server/internal/migrations"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/sirupsen/logrus"
)

var (
	ErrMigrationTargetTooLow    = errors.New("schema migration target cannot be less than 0")
	ErrMigrationTargetTooHigh   = errors.New("schema migration target cannot be greater than latest")
	ErrMigrationNoAutoDowngrade = errors.New("will not auto-downgrade schema to prevent data loss")
)

var currentSchemaVersion int
var latestSchemaVersion int

type DbHandler struct {
	pool    *pgxpool.Pool
	queries *sql.Queries
}

func NewDb(dsn string, trace, autoMigrate bool) (*DbHandler, error) {
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, errors.New("Unable to parse DSN: " + err.Error())
	}

	if trace {
		config.ConnConfig.Tracer = tracer{}
	}

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return nil, errors.New("Unable to connect to database: " + err.Error())
	}

	logrus.Info("Connected to " + config.ConnConfig.Database + " at " + config.ConnConfig.Host + ":" + fmt.Sprint(config.ConnConfig.Port))

	conn, err := pool.Acquire(context.Background())
	if err != nil {
		return nil, err
	}
	migrator, err := migrations.NewMigrator(conn.Conn())
	if err != nil {
		return nil, err
	}
	currentSchemaVersion, err = migrator.GetCurrentVersion()
	if err != nil {
		return nil, err
	}
	latestSchemaVersion = migrator.GetLatestVersion()
	conn.Release()

	handler := &DbHandler{
		pool:    pool,
		queries: sql.New(pool),
	}

	if currentSchemaVersion != latestSchemaVersion {
		logrus.Warn(fmt.Sprintf("Schema version %d (latest %d)", currentSchemaVersion, latestSchemaVersion))
		if autoMigrate {
			if currentSchemaVersion > latestSchemaVersion {
				return nil, ErrMigrationNoAutoDowngrade
			}
			if err := handler.Migrate(latestSchemaVersion); err != nil {
				return nil, err
			}
		}
	} else {
		logrus.Info(fmt.Sprintf("Schema version %d", currentSchemaVersion))
	}

	return handler, nil
}

func (d DbHandler) Migrate(version int) error {
	conn, err := d.pool.Acquire(context.Background())
	if err != nil {
		return err
	}
	defer conn.Release()
	if version < 0 {
		return ErrMigrationTargetTooLow
	}
	if version > latestSchemaVersion {
		return ErrMigrationTargetTooHigh
	}
	migrator, err := migrations.NewMigrator(conn.Conn())
	if err != nil {
		return err
	}
	logrus.Info(fmt.Sprintf("Migrating database from version %d to %d", currentSchemaVersion, version))
	if err = migrator.MigrateTo(int32(version)); err != nil {
		return err
	}
	return nil
}

func (d DbHandler) Queries() *sql.Queries {
	return d.queries
}

func (d DbHandler) RunInTx(ctx context.Context, fn func(*sql.Queries) error) error {
	return pgx.BeginFunc(ctx, d.pool, func(tx pgx.Tx) error {
		q := d.queries.WithTx(tx)
		return fn(q)
	})
}

func (d DbHandler) Close() {
	d.pool.Close()
}
