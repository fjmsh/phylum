package sql

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/shroff/phylum/server/internal/migrations"
	"github.com/sirupsen/logrus"
)

type DbHandler struct {
	pool    *pgxpool.Pool
	queries *Queries
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

	if migrator, err := migrations.NewMigrator(pool); err != nil {
		panic(err)
	} else {
		version, err := migrator.GetCurrentVersion()
		if err != nil {
			panic(err)
		}
		latest := migrator.GetLatestVersion()
		if version != latest {
			if autoMigrate {
				logrus.Info(fmt.Sprintf("Migrating database from version %d to %d", version, latest))
				migrator.Migrate()
			} else {
				panic(fmt.Sprintf("Schema is not at latest version (current %d, latest %d)", version, latest))
			}
		}

	}

	return &DbHandler{
		pool:    pool,
		queries: &Queries{db: pool},
	}, nil
}

func (d DbHandler) Queries() *Queries {
	return d.queries
}

func (d DbHandler) RunInTx(ctx context.Context, fn func(*Queries) error) error {
	return pgx.BeginFunc(ctx, d.pool, func(tx pgx.Tx) error {
		q := d.queries.WithTx(tx)
		return fn(q)
	})
}

func (d DbHandler) Close() {
	d.pool.Close()
}
