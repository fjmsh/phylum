package db

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

const DefaultUserUsername = "phylum"
const DefaultUserDisplayName = "Phylum"

func BootstrapData(ctx context.Context) error {
	const q = "SELECT username FROM users WHERE username = $1::TEXT"
	d := Get()
	row := d.QueryRow(ctx, q, DefaultUserUsername)
	if err := row.Scan(nil); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = d.RunInTx(ctx, func(d Handler) error {
				const createDir = `INSERT INTO resources(id, parent, name, dir, content_length, content_type, content_sha256)
VALUES ($1::UUID, $2::UUID, $3::TEXT, TRUE, 0, '', '')`

				// Create root folder
				rootID, _ := uuid.NewV7()
				if _, err := d.Exec(ctx, createDir, rootID, nil, ""); err != nil {
					return err
				}

				// Create home folder
				homeID, _ := uuid.NewV7()
				if _, err := d.Exec(ctx, createDir, homeID, rootID, "home"); err != nil {
					return err
				}

				// Create user home folder
				userHomeID, _ := uuid.NewV7()
				if _, err := d.Exec(ctx, createDir, userHomeID, homeID, DefaultUserUsername); err != nil {
					return err
				}

				const createRootUser = `INSERT INTO users(username, display_name, password_hash, root, home, permissions)
VALUES ($1::TEXT, $2::TEXT, '', $3::UUID, $4::UUID, -1)`

				if _, err := d.Exec(ctx, createRootUser, DefaultUserUsername, DefaultUserDisplayName, rootID, userHomeID); err != nil {
					return err
				}
				return nil

			})
		}
		if err != nil {
			return err
		}
	}

	return nil
}
