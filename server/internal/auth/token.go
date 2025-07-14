package auth

import (
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

func PerformTokenLogin(db db.TxHandler, token string) (a Auth, key string, err error) {
	row := db.QueryRow("DELETE FROM pending_logins WHERE token = $1 AND user_id IS NOT NULL RETURNING user_id, expires", token)
	var user core.User
	var userID int32
	var expires time.Time
	if err = row.Scan(&userID, &expires); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrTokenInvalid
		}
		return
	} else if expires.Before(time.Now()) {
		err = ErrTokenInvalid
		return
	} else if user, err = core.UserByID(db, userID); err != nil {
		return
	} else if key, err = GenerateAPIKey(db, userID, 0, "", []string{"*"}); err != nil {
		return
	} else {
		a = auth{
			userID:          user.ID,
			homeID:          user.Home,
			userPermissions: user.Permissions,
			scopes:          []string{"*"},
		}
		return
	}
}
