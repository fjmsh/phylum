package db

import (
	"context"
	"fmt"

	"github.com/shroff/phylum/server/internal/core/db/migrations"
	"github.com/sirupsen/logrus"
)

func (d DbHandler) checkVersion(ctx context.Context, autoMigrate bool) error {
	conn, err := d.pool.Acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()

	migrator, err := migrations.NewMigrator(ctx, conn.Conn())
	currentSchemaVersion, err := migrator.GetCurrentVersion(ctx)
	if err != nil {
		return err
	}
	latestSchemaVersion := migrator.GetLatestVersion()
	if err != nil {
		return err
	}

	// Nothing to do
	if currentSchemaVersion == latestSchemaVersion {
		return nil
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
	return migrator.MigrateTo(ctx, int32(latestSchemaVersion))
}

func (d DbHandler) Migrate(ctx context.Context, version int) error {
	conn, err := d.pool.Acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()

	migrator, err := migrations.NewMigrator(ctx, conn.Conn())
	currentSchemaVersion, err := migrator.GetCurrentVersion(ctx)
	if err != nil {
		return err
	}
	latestSchemaVersion := migrator.GetLatestVersion()
	if err != nil {
		return err
	}
	if version < 0 {
		version = latestSchemaVersion
	} else if version == 0 {
		return d.DeleteSchema(ctx)
	} else if version > latestSchemaVersion {
		return ErrMigrationTargetTooHigh
	}

	logrus.Info(fmt.Sprintf("Migrating database from version %d to %d", currentSchemaVersion, version))
	return migrator.MigrateTo(ctx, int32(version))
}

func (d DbHandler) DeleteSchema(ctx context.Context) error {
	return d.WithTx(ctx, func(d *DbHandler) (err error) {
		user := d.pool.Config().ConnConfig.User
		if err = d.Exec(ctx, "DROP SCHEMA public CASCADE"); err != nil {
			return
		}
		if err = d.Exec(ctx, "CREATE SCHEMA public"); err != nil {
			return
		}
		if err = d.Exec(ctx, "GRANT ALL ON SCHEMA public TO "+user); err != nil {
			return
		}
		if err = d.Exec(ctx, "GRANT ALL ON SCHEMA public TO public"); err != nil {
			return
		}
		return d.Exec(ctx, "COMMENT ON SCHEMA public IS 'standard public schema'")
	})
}
