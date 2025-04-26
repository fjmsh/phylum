package db

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/sirupsen/logrus"
	"github.com/spf13/viper"
)

var Config *viper.Viper

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
	dsn.WriteString("host=" + Config.GetString("host"))
	dsn.WriteString(" port=" + Config.GetString("port"))
	dsn.WriteString(" dbname=" + Config.GetString("name"))
	dsn.WriteString(" user=" + Config.GetString("user"))
	if Config.GetString("password") != "" {
		dsn.WriteString(" password=" + Config.GetString("password"))
	}

	config, err := pgxpool.ParseConfig(dsn.String())
	if err != nil {
		return errors.New("Unable to parse DSN: " + err.Error())
	}

	if Config.GetBool("trace_queries") {
		config.ConnConfig.Tracer = tracer{}
	}

	pool, err = pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return errors.New("Unable to connect to database: " + err.Error())
	}

	logrus.Debug("Connected to " + config.ConnConfig.Database + " at " + config.ConnConfig.Host + ":" + fmt.Sprint(config.ConnConfig.Port))

	if err := checkVersion(ctx, Config.GetBool("skip_migration")); err != nil {
		return err
	}

	return nil
}
