package auth

import (
	"errors"
	"net/http"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

func PerformTokenLogin(db db.TxHandler, token string) (core.User, string, error) {
	row := db.QueryRow("DELETE FROM pending_logins WHERE token = $1 AND user_id IS NOT NULL RETURNING user_id, expires", token)
	var userID int32
	var expires time.Time
	if err := row.Scan(&userID, &expires); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = core.NewError(http.StatusBadRequest, "login_token_invalid", "The given login token is invalid")
		}
		return core.User{}, "", err
	} else if expires.Before(time.Now()) {
		return core.User{}, "", core.NewError(http.StatusBadRequest, "login_token_invalid", "The given login token is invalid")
	} else if user, err := core.UserByID(db, userID); err != nil {
		return core.User{}, "", err
	} else if token, err := insertAPIKey(db, userID, ""); err != nil {
		return core.User{}, "", err
	} else {
		return user, token, err
	}
}
