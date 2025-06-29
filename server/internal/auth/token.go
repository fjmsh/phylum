package auth

import (
	"errors"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

func PerformTokenLogin(db db.TxHandler, token string) (core.User, string, error) {
	row := db.QueryRow("DELETE FROM pending_logins WHERE token = $1 AND user_id IS NOT NULL RETURNING user_id", token)
	var userID int32
	if err := row.Scan(&userID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = errors.New("login token invalid")
		}
		return core.User{}, "", err
	} else if user, err := core.UserByID(db, userID); err != nil {
		return core.User{}, "", err
	} else if token, err := insertAPIKey(db, userID); err != nil {
		return core.User{}, "", err
	} else {
		return user, token, err
	}
}
