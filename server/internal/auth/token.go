package auth

import (
	"errors"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

func PerformTokenLogin(db db.TxHandler, loginToken string) (core.User, string, error) {
	row := db.QueryRow("DELETE FROM openid_sessions WHERE id = $1 AND user_id IS NOT NULL RETURNING user_id", loginToken)
	var userID int32
	if err := row.Scan(&userID); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = errors.New("state token invalid")
		}
		return core.User{}, "", err
	} else if user, err := core.UserByID(db, userID); err != nil {
		return core.User{}, "", err
	} else if token, err := insertAccessToken(db, userID); err != nil {
		return core.User{}, "", err
	} else {
		return user, token, err
	}
}
