package auth

import (
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
)

func PerformTokenLogin(db db.TxHandler, token string) (Auth, string, error) {
	row := db.QueryRow("DELETE FROM pending_logins WHERE token = $1 AND user_id IS NOT NULL RETURNING user_id, expires", token)
	var userID int32
	var expires time.Time
	if err := row.Scan(&userID, &expires); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrTokenInvalid
		}
		return nil, "", err
	} else if expires.Before(time.Now()) {
		return nil, "", ErrTokenInvalid
	} else if user, err := core.UserByID(db, userID); err != nil {
		return nil, "", err
	} else if token, err := insertAPIKey(db, userID, 0, "", []string{"*"}); err != nil {
		return nil, "", err
	} else {
		return auth{userID: user.ID, userPermissions: user.Permissions, scopes: []string{"*"}}, token, err
	}
}
