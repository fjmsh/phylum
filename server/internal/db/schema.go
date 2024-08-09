package db

import (
	"context"
	"fmt"

	"github.com/shroff/phylum/server/internal/db/migrations"
	"github.com/sirupsen/logrus"
)

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
