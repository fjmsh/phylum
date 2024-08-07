package db

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shroff/phylum/server/internal/db/migrations"
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
	queries *Queries
}

func NewDb(ctx context.Context, dsn string, trace bool) (*DbHandler, error) {
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, errors.New("Unable to parse DSN: " + err.Error())
	}

	if trace {
		config.ConnConfig.Tracer = tracer{}
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, errors.New("Unable to connect to database: " + err.Error())
	}

	logrus.Info("Connected to " + config.ConnConfig.Database + " at " + config.ConnConfig.Host + ":" + fmt.Sprint(config.ConnConfig.Port))

	conn, err := pool.Acquire(ctx)
	if err != nil {
		return nil, err
	}
	migrator, err := migrations.NewMigrator(ctx, conn.Conn())
	if err != nil {
		return nil, err
	}
	currentSchemaVersion, err = migrator.GetCurrentVersion(ctx)
	if err != nil {
		return nil, err
	}
	latestSchemaVersion = migrator.GetLatestVersion()
	conn.Release()

	handler := &DbHandler{
		pool:    pool,
		queries: New(pool),
	}

	return handler, nil
}

func (d DbHandler) CheckVersion(ctx context.Context, autoMigrate bool) error {
	logrus.Info(fmt.Sprintf("Schema version %d", currentSchemaVersion))
	if currentSchemaVersion != latestSchemaVersion {
		if autoMigrate {
			if currentSchemaVersion > latestSchemaVersion {
				return ErrMigrationNoAutoDowngrade
			}
			if currentSchemaVersion == latestSchemaVersion {
				return nil
			}
			return d.Migrate(ctx, latestSchemaVersion)
		} else {
			logrus.Warn(fmt.Sprintf("Schema version is not at latest (%d)", latestSchemaVersion))
			return nil
		}
	}
	return nil
}

func (d DbHandler) Migrate(ctx context.Context, version int) error {
	conn, err := d.pool.Acquire(ctx)
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
	migrator, err := migrations.NewMigrator(ctx, conn.Conn())
	if err != nil {
		return err
	}
	logrus.Info(fmt.Sprintf("Migrating database from version %d to %d", currentSchemaVersion, version))
	if err = migrator.MigrateTo(ctx, int32(version)); err != nil {
		return err
	}
	return nil
}

func (d DbHandler) DeleteSchema(ctx context.Context) (e error) {
	return pgx.BeginFunc(ctx, d.pool, func(tx pgx.Tx) error {
		user := d.pool.Config().ConnConfig.User
		_, err := tx.Exec(ctx, "DROP SCHEMA public CASCADE;"+
			"CREATE SCHEMA public;"+
			"GRANT ALL ON SCHEMA public TO "+user+";"+
			"GRANT ALL ON SCHEMA public TO public;"+
			"COMMENT ON SCHEMA public IS 'standard public schema';")

		return err
	})
}

func (d DbHandler) Queries() *Queries {
	return d.queries
}

func (d DbHandler) RunInTx(ctx context.Context, fn func(pgx.Tx) error) error {
	return pgx.BeginFunc(ctx, d.pool, func(tx pgx.Tx) error {
		return fn(tx)
	})
}

func (d DbHandler) WithTx(ctx context.Context, fn func(*Queries) error) error {
	return pgx.BeginFunc(ctx, d.pool, func(tx pgx.Tx) error {
		q := d.queries.WithTx(tx)
		return fn(q)
	})
}

func (d DbHandler) Close() {
	d.pool.Close()
}
