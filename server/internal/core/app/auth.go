package app

import (
	"context"
	"net/http"
	"time"
	"unsafe"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/errors"
	"golang.org/x/exp/rand"
)

const accessTokenLength = 16

var accessTokenValiditiy = pgtype.Interval{
	Days:  30,
	Valid: true,
}

var ErrCredentialsInvalid = errors.NewError(http.StatusUnauthorized, "credentials_invalid", "invalid Credentials")

func (a App) VerifyUserPassword(ctx context.Context, email, password string) (User, error) {
	if user, err := a.db.UserByUsername(ctx, email); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return User{}, ErrCredentialsInvalid
		}
		return User{}, err
	} else {
		if b, err := verifyPassword(password, user.PasswordHash); err != nil {
			return User{}, err
		} else if !b {
			return User{}, ErrCredentialsInvalid
		}
		return User{
			Username:    user.Username,
			DisplayName: user.DisplayName,
			Root:        user.Root,
			Home:        user.Home,
		}, nil
	}
}

func (a App) CreateAccessToken(ctx context.Context, username string) (string, error) {
	if token, err := a.db.InsertAccessToken(ctx, db.InsertAccessTokenParams{
		ID:       GenerateRandomString(accessTokenLength),
		Validity: accessTokenValiditiy,
		Username: username,
	}); err != nil {
		return "", err
	} else {
		return token.ID, nil
	}
}

func (a App) ReadAccessToken(ctx context.Context, accessToken string) (User, error) {
	token, err := a.db.AccessTokenById(ctx, accessToken)
	if errors.Is(err, pgx.ErrNoRows) {
		return User{}, ErrCredentialsInvalid
	} else if err != nil {
		return User{}, err
	}
	if time.Now().After(token.Expires.Time) {
		return User{}, ErrCredentialsInvalid
	}
	return User{
		Username:    token.Username,
		DisplayName: token.DisplayName,
		Root:        token.Root,
		Home:        token.Home,
	}, nil
}

const (
	letterBytes   = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
	letterIdxBits = 6                    // 6 bits to represent a letter index
	letterIdxMask = 1<<letterIdxBits - 1 // All 1-bits, as many as letterIdxBits
	letterIdxMax  = 64 / letterIdxBits   // # of letter indices fitting in 64 bits
)

func GenerateRandomString(n int) string {
	src := rand.NewSource(uint64(time.Now().UnixNano()))
	b := make([]byte, n)
	for i, cache, remain := n-1, src.Uint64(), letterIdxMax; i >= 0; {
		if remain == 0 {
			cache, remain = src.Uint64(), letterIdxMax
		}
		idx := int(cache & letterIdxMask)
		// if idx < len(letterBytes)
		b[i] = letterBytes[idx]
		i--
		cache >>= letterIdxBits
		remain--
	}

	return *(*string)(unsafe.Pointer(&b))
}
