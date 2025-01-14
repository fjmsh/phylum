package db

import (
	"context"
	"errors"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

const DefaultUserUsername = "phylum"
const DefaultUserDisplayName = "Phylum"

func (d DbHandler) BootstrapData(ctx context.Context) error {
	if _, err := d.UserByUsername(ctx, DefaultUserUsername); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = d.populateData(ctx)
		}
		if err != nil {
			return err
		}
	}

	return nil
}

func (d DbHandler) populateData(ctx context.Context) (e error) {
	return d.WithTx(ctx, func(dbh *DbHandler) error {
		var err error

		// Create root folder
		id, _ := uuid.NewV7()
		root, err := dbh.CreateResource(ctx, CreateResourceParams{
			ID:   id,
			Name: "",
			Dir:  true,
		})
		if err != nil {
			return err
		}

		// Create home folder
		id, _ = uuid.NewV7()
		home, err := dbh.CreateResource(ctx, CreateResourceParams{
			ID:     id,
			Parent: &root.ID,
			Name:   "home",
			Dir:    true,
		})
		if err != nil {
			return err
		}

		// Create user home folder
		id, _ = uuid.NewV7()
		userHome, err := dbh.CreateResource(ctx, CreateResourceParams{
			ID:     id,
			Parent: &home.ID,
			Name:   DefaultUserUsername,
			Dir:    true,
		})
		if err != nil {
			return err
		}

		// Create phylum user
		_, err = dbh.CreateUser(ctx, CreateUserParams{
			Username:     DefaultUserUsername,
			DisplayName:  DefaultUserDisplayName,
			PasswordHash: "CANNOT LOG IN",
			Root:         root.ID,
			Home:         userHome.ID,
		})
		if err != nil {
			return err
		}

		return dbh.GrantUserPermissions(ctx, GrantUserPermissionsParams{
			Username:    DefaultUserUsername,
			Permissions: -1,
		})
	})
}
