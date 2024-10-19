package migrations

import (
	"context"
	"embed"
	"io/fs"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/tern/v2/migrate"
)

const versionTable = "db_version"

type Migrator struct {
	migrator *migrate.Migrator
}

//go:embed data/*.sql
var migrationFiles embed.FS

func NewMigrator(ctx context.Context, conn *pgx.Conn) (Migrator, error) {
	migrator, err := migrate.NewMigratorEx(
		ctx, conn, versionTable,
		&migrate.MigratorOptions{
			DisableTx: false,
		})
	if err != nil {
		return Migrator{}, err
	}

	migrationRoot, _ := fs.Sub(migrationFiles, "data")

	err = migrator.LoadMigrations(migrationRoot)
	if err != nil {
		return Migrator{}, err
	}

	return Migrator{
		migrator: migrator,
	}, nil
}

func (m Migrator) GetCurrentVersion(ctx context.Context) (int, error) {
	version, err := m.migrator.GetCurrentVersion(ctx)
	if err != nil {
		return 0, err
	}

	return int(version), nil
}

func (m Migrator) GetLatestVersion() int {
	return len(m.migrator.Migrations)
}

func (m Migrator) Migrations() []*migrate.Migration {
	return m.migrator.Migrations
}

// Migrate migrates the DB to the most recent version of the schema.
func (m Migrator) Migrate(ctx context.Context) error {
	err := m.migrator.Migrate(ctx)
	return err
}

// MigrateTo migrates to a specific version of the schema. Use '0' to undo all migrations.
func (m Migrator) MigrateTo(ctx context.Context, ver int32) error {
	err := m.migrator.MigrateTo(ctx, ver)
	return err
}
