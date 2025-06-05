package core

import (
	"net/http"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/rand"
)

var ErrTokenNotFound = NewError(http.StatusBadRequest, "token_not_found", "Token Not Found")

const resetTokenLength = 64
const resetTokenDuration = 10 * time.Minute

func (m manager) CreateResetToken(user User) (string, error) {
	const q = `INSERT INTO reset_tokens(user_id, token, expires)
VALUES (@user_id::INT, @token::TEXT, @expires::TIMESTAMP)
ON CONFLICT(user_id) DO UPDATE SET token = @token::TEXT, expires = @expires::TIMESTAMP`
	token := rand.GenerateRandomString(resetTokenLength)

	args := pgx.NamedArgs{
		"user_id": user.ID,
		"token":   token,
		"expires": time.Now().Add(resetTokenDuration),
	}
	if _, err := m.db.Exec(q, args); err != nil {
		return "", err
	}
	return token, nil
}

func (m manager) ResetUserPassword(user User, token, password string) error {
	const q = `DELETE FROM reset_tokens WHERE user_id = @user_id::INT AND token = @token::TEXT RETURNING expires`
	args := pgx.NamedArgs{
		"user_id": user.ID,
		"token":   token,
		"expires": time.Now().Add(resetTokenDuration),
	}
	return m.db.RunInTx(func(d db.Handler) error {
		m := m.withDb(d)

		// UpdateUserPassword will ensure the password strength
		// Not incorrect to do this before token verification because we are in a transaction.
		// TODO: Are there perf implications for this in case of malicious actors?
		err := m.UpdateUserPassword(user, password)
		if err != nil {
			return err
		}
		row := m.db.QueryRow(q, args)
		var expires pgtype.Timestamp
		if err := row.Scan(&expires); err == nil {
			if time.Now().After(expires.Time) {
				return ErrTokenNotFound
			}
			return nil
		} else if Is(err, pgx.ErrNoRows) {
			return ErrTokenNotFound
		} else {
			return err
		}
	})

}
