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

func (h Handler) checkVersion(ctx context.Context, autoMigrate bool) error {
	conn, err := h.pool.Acquire(ctx)
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
		return h.BootstrapData(ctx)
	}

	if !autoMigrate {
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
	return h.BootstrapData(ctx)
}

func (h Handler) Migrate(ctx context.Context, version int) error {
	conn, err := h.pool.Acquire(ctx)
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
		return h.DeleteSchema(ctx)
	} else if version > latestSchemaVersion {
		return ErrMigrationTargetTooHigh
	}

	logrus.Info(fmt.Sprintf("Migrating database from version %d to %d", currentSchemaVersion, version))
	err = migrator.MigrateTo(ctx, int32(version))
	if err != nil {
		return err
	}
	if version == latestSchemaVersion {
		return h.BootstrapData(ctx)
	}
	return nil
}

func (h Handler) DeleteSchema(ctx context.Context) error {
	return h.RunInTx(ctx, func(d *Handler) (err error) {
		user := d.pool.Config().ConnConfig.User
		if _, err = d.Exec(ctx, "DROP SCHEMA public CASCADE"); err != nil {
			return
		}
		if _, err = d.Exec(ctx, "CREATE SCHEMA public"); err != nil {
			return
		}
		if _, err = d.Exec(ctx, "GRANT ALL ON SCHEMA public TO "+user); err != nil {
			return
		}
		if _, err = d.Exec(ctx, "GRANT ALL ON SCHEMA public TO public"); err != nil {
			return
		}
		_, err = d.Exec(ctx, "COMMENT ON SCHEMA public IS 'standard public schema'")
		return
	})
}
