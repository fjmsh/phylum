package db

import (
	"context"
	"errors"
	"strconv"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/pubsub"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/rs/zerolog/log"
)

var Cfg Config

var pool *pgxpool.Pool
var notifier pubsub.Notifier

func Get(ctx context.Context) Handler {
	if pool == nil {
		if err := initPool(context.Background()); err != nil {
			log.Fatal().Err(err).Msg("failed to initialize db pool")
		} else if n, err := pubsub.Start(pool, context.Background()); err != nil {
			log.Fatal().Err(err).Msg("failed to initialize pubsub client")
		} else {
			notifier = n
		}
	}
	return handler{
		ctx: ctx,
		db:  pool,
	}
}

func RunInTx(ctx context.Context, fn func(TxHandler) error) error {
	return Get(ctx).RunInTx(fn)
}

// Pool returns the pgx pool
// Only to be used for jobs initialization
func Pool() *pgxpool.Pool {
	return pool
}

func Notifier() pubsub.Notifier {
	return notifier
}

func Close() {
	if pool != nil {
		pool.Close()
		pool = nil
	}
}

func initPool(ctx context.Context) error {
	var dsn strings.Builder
	dsn.WriteString("host=" + Cfg.Host)
	dsn.WriteString(" port=" + strconv.Itoa(Cfg.Port))
	dsn.WriteString(" dbname=" + Cfg.Name)
	dsn.WriteString(" user=" + Cfg.User)
	if Cfg.Password != "" {
		dsn.WriteString(" password=" + Cfg.Password)
	}

	config, err := pgxpool.ParseConfig(dsn.String())
	if err != nil {
		return errors.New("Unable to parse DSN: " + err.Error())
	}

	if Cfg.Trace {
		config.ConnConfig.Tracer = tracer{}
	}

	pool, err = pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return err
	}

	log.Debug().Str("host", config.ConnConfig.Host+":"+strconv.Itoa(int(config.ConnConfig.Port))).
		Str("db", config.ConnConfig.Database).
		Msg("Connected to database")

	if err := checkVersion(ctx, Cfg.NoMigrate); err != nil {
		return err
	}

	return nil
}
