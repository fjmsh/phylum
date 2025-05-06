package db

import (
	"context"
	"errors"
	"fmt"

	"github.com/shroff/phylum/server/internal/core/db/migrations"
	"github.com/sirupsen/logrus"
)

var (
	ErrMigrationTargetTooLow    = errors.New("schema migration target cannot be less than 0")
	ErrMigrationTargetTooHigh   = errors.New("schema migration target cannot be greater than latest")
	ErrMigrationNoAutoDowngrade = errors.New("will not auto-downgrade schema to prevent data loss")
)

func checkVersion(ctx context.Context, skipMigration bool) error {
	conn, err := pool.Acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()

	migrator, err := migrations.NewMigrator(ctx, conn.Conn())
	if err != nil {
		return err
	}
	currentSchemaVersion, err := migrator.GetCurrentVersion(ctx)
	if err != nil {
		return err
	}
	latestSchemaVersion := migrator.GetLatestVersion()

	// Nothing to do
	if currentSchemaVersion == latestSchemaVersion {
		return nil
	}

	if skipMigration {
		logrus.Warn(fmt.Sprintf("Database schema is not at current version: %d/%d", currentSchemaVersion, latestSchemaVersion))
		return nil
	}
	if currentSchemaVersion > latestSchemaVersion {
		logrus.Warn(fmt.Sprintf("Not automatically downgrading schema from %d to %d", currentSchemaVersion, latestSchemaVersion))
		return nil
	}

	logrus.Info(fmt.Sprintf("Migrating database from version %d to %d", currentSchemaVersion, latestSchemaVersion))
	err = migrator.MigrateTo(ctx, int32(latestSchemaVersion))
	if err != nil {
		return err
	}
	return nil
}

func Migrate(ctx context.Context, version int) error {
	Get(ctx) // Initialize the pool, just in case
	conn, err := pool.Acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()

	migrator, err := migrations.NewMigrator(ctx, conn.Conn())
	if err != nil {
		return err
	}
	currentSchemaVersion, err := migrator.GetCurrentVersion(ctx)
	if err != nil {
		return err
	}
	latestSchemaVersion := migrator.GetLatestVersion()
	if version < 0 {
		version = latestSchemaVersion
	} else if version == 0 {
		logrus.Info("Deleting database schema")
		return DeleteSchema(ctx)
	} else if version > latestSchemaVersion {
		return ErrMigrationTargetTooHigh
	}

	logrus.Info(fmt.Sprintf("Migrating database from version %d to %d", currentSchemaVersion, version))
	err = migrator.MigrateTo(ctx, int32(version))
	if err != nil {
		return err
	}
	if version == latestSchemaVersion {
		return nil
	}
	return nil
}

func DeleteSchema(ctx context.Context) error {
	h := Get(ctx)
	user := pool.Config().ConnConfig.User
	return h.RunInTx(func(d Handler) (err error) {
		if _, err = d.Exec("DROP SCHEMA public CASCADE"); err != nil {
			return
		}
		if _, err = d.Exec("CREATE SCHEMA public"); err != nil {
			return
		}
		if _, err = d.Exec("GRANT ALL ON SCHEMA public TO " + user); err != nil {
			return
		}
		if _, err = d.Exec("GRANT ALL ON SCHEMA public TO public"); err != nil {
			return
		}
		_, err = d.Exec("COMMENT ON SCHEMA public IS 'standard public schema'")
		return
	})
}
