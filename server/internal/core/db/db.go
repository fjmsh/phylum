package db

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/sirupsen/logrus"
)

var Cfg Config

var pool *pgxpool.Pool

func Get(ctx context.Context) Handler {
	if pool == nil {
		if err := initPool(context.Background()); err != nil {
			logrus.Fatal(err)
		}
	}
	return Handler{
		ctx: ctx,
		tx:  pool,
	}
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
		return errors.New("Unable to connect to database: " + err.Error())
	}

	logrus.Debug("Connected to " + config.ConnConfig.Database + " at " + config.ConnConfig.Host + ":" + fmt.Sprint(config.ConnConfig.Port))

	if err := checkVersion(ctx, Cfg.NoMigrate); err != nil {
		return err
	}

	return nil
}
