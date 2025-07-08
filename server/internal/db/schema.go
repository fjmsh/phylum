package db

import (
	"context"
	"embed"
	"io/fs"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/jackc/tern/v2/migrate"
)

const versionTable = "db_version"

//go:embed migrations/*.sql
var migrationFiles embed.FS

type SchemaInfo struct {
	pool           *pgxpool.Pool
	CurrentVersion int32
	LatestVersion  int32
}

func GetSchemaInfo(ctx context.Context, pool *pgxpool.Pool) (SchemaInfo, error) {
	conn, err := pool.Acquire(ctx)
	if err != nil {
		return SchemaInfo{}, err
	}
	defer conn.Release()

	migrator, err := createMigrator(ctx, conn.Conn())
	if err != nil {
		return SchemaInfo{}, err
	}

	currentVersion, err := migrator.GetCurrentVersion(ctx)
	if err != nil {
		return SchemaInfo{}, err
	}

	return SchemaInfo{
		pool:           pool,
		CurrentVersion: currentVersion,
		LatestVersion:  int32(len(migrator.Migrations)),
	}, nil
}

// MigrateTo migrates to a specific version of the schema. Use '0' to undo all migrations.
func (s SchemaInfo) MigrateTo(ctx context.Context, ver int32) error {
	conn, err := s.pool.Acquire(ctx)
	if err != nil {
		return err
	}
	defer conn.Release()
	if migrator, err := createMigrator(ctx, conn.Conn()); err != nil {
		return err
	} else {
		return migrator.MigrateTo(ctx, ver)
	}
}

func createMigrator(ctx context.Context, conn *pgx.Conn) (*migrate.Migrator, error) {
	m, err := migrate.NewMigratorEx(ctx, conn, versionTable, &migrate.MigratorOptions{DisableTx: false})
	if err != nil {
		return nil, err
	}

	migrationRoot, _ := fs.Sub(migrationFiles, "migrations")
	if err := m.LoadMigrations(migrationRoot); err != nil {
		return nil, err
	}
	return m, nil
}

func ResetSchema(ctx context.Context, pool *pgxpool.Pool) error {
	user := pool.Config().ConnConfig.User
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, "DROP SCHEMA public CASCADE"); err != nil {
			return err
		}
		if _, err := tx.Exec(ctx, "CREATE SCHEMA public"); err != nil {
			return err
		}
		if _, err := tx.Exec(ctx, "GRANT ALL ON SCHEMA public TO "+user); err != nil {
			return err
		}
		if _, err := tx.Exec(ctx, "GRANT ALL ON SCHEMA public TO public"); err != nil {
			return err
		}
		if _, err := tx.Exec(ctx, "COMMENT ON SCHEMA public IS 'standard public schema'"); err != nil {
			return err
		}
		return nil
	})
}
