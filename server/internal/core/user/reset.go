package user

import (
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/core/util/rand"
)

const resetTokenLength = 16
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
