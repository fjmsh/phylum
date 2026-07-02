package db

import (
	"context"
	"errors"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog"
)

var pool *pgxpool.Pool

func Initialize(ctx context.Context, cfg Config, log *zerolog.Logger) (*pgxpool.Pool, error) {
	if pool != nil {
		return nil, errors.New("db pool already initialized")
	}

	if p, err := Connect(ctx, cfg, log); err != nil {
		return nil, errors.New("failed to initialize db pool: " + err.Error())
	} else if err := p.Ping(ctx); err != nil {
		return nil, errors.New("failed to connect to db: " + err.Error())
	} else {
		pool = p
	}

	// Migrate schema
	if !cfg.NoMigrate {
		if s, err := GetSchemaInfo(ctx, pool); err != nil {
			pool = nil
			return nil, errors.New("failed to get schema info: " + err.Error())
		} else if s.CurrentVersion != s.LatestVersion {
			log.Info().Int32("current", s.CurrentVersion).Int32("latest", s.LatestVersion).Msg("Performing schema migration")
			if err := s.MigrateTo(ctx, int32(s.LatestVersion)); err != nil {
				pool = nil
				return nil, errors.New("failed to perform schema migration")
			}
		}
	}

	return pool, nil
}

func Get(ctx context.Context) Handler {
	return handler{
		ctx: ctx,
		db:  pool,
	}
}

func RunInTx(ctx context.Context, fn func(TxHandler) error) error {
	return Get(ctx).RunInTx(fn)
}

func Close() {
	if pool != nil {
		pool.Close()
		pool = nil
	}
}

func Connect(ctx context.Context, cfg Config, logger *zerolog.Logger) (*pgxpool.Pool, error) {
	var dsn strings.Builder
	dsn.WriteString("host=")
	dsn.WriteString(cfg.Host)
	dsn.WriteString(" port=")
	dsn.WriteString(strconv.Itoa(cfg.Port))
	dsn.WriteString(" dbname=")
	dsn.WriteString(cfg.Name)
	dsn.WriteString(" user=")
	dsn.WriteString(cfg.User)
	if cfg.Password != "" {
		dsn.WriteString(" password=")
		dsn.WriteString(cfg.Password)
	}

	config, err := pgxpool.ParseConfig(dsn.String())
	if err != nil {
		return nil, errors.New("failed to parse DSN: " + err.Error())
	}

	if cfg.Trace && logger != nil {
		config.ConnConfig.Tracer = tracer{
			log: logger.With().Str("mod", "db.trace").Logger().Level(zerolog.TraceLevel),
		}
	}

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, errors.New("failed to create pool: " + err.Error())
	}

	if logger != nil {
		logger.Debug().
			Str("host", config.ConnConfig.Host+":"+strconv.Itoa(int(config.ConnConfig.Port))).
			Str("db", config.ConnConfig.Database).
			Msg("Connected to database")
	}

	return pool, nil
}
