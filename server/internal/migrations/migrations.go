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

func NewMigrator(conn *pgx.Conn) (Migrator, error) {
	migrator, err := migrate.NewMigratorEx(
		context.Background(), conn, versionTable,
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

func (m Migrator) GetCurrentVersion() (int, error) {
	version, err := m.migrator.GetCurrentVersion(context.Background())
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
func (m Migrator) Migrate() error {
	err := m.migrator.Migrate(context.Background())
	return err
}

// MigrateTo migrates to a specific version of the schema. Use '0' to undo all migrations.
func (m Migrator) MigrateTo(ver int32) error {
	err := m.migrator.MigrateTo(context.Background(), ver)
	return err
}
