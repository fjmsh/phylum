package user

import (
	"net/http"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/errors"
)

var ErrNotFound = errors.NewError(http.StatusNotFound, "user_not_found", "no such user")

func (m manager) AllUsers() ([]User, error) {
	results, err := m.db.AllUsers(m.ctx)
	if err != nil {
		return nil, err
	}
	users := make([]User, len(results))
	for i, r := range results {
		users[i] = User{
			Username:    r.Username,
			DisplayName: r.DisplayName,
			Root:        r.Root,
			Home:        r.Home,
		}
	}
	return users, nil
}

func (m manager) UserByEmail(email string) (User, error) {
	result, err := m.db.UserByUsername(m.ctx, email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrNotFound
		}
		return User{}, err
	}
	return User{
		Username:    result.Username,
		DisplayName: result.DisplayName,
		Root:        result.Root,
		Home:        result.Home,
	}, nil
}
