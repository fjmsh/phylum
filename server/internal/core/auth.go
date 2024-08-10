package core

import (
	"context"
	"errors"
	"time"
	"unsafe"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/db"
	"golang.org/x/exp/rand"
)

const accessTokenLength = 16

var accessTokenValiditiy = pgtype.Interval{
	Days:  30,
	Valid: true,
}

var ErrCredentialsInvalid = errors.New("credentials invalid")
var ErrTokenInvalid = errors.New("token invalid")
var ErrTokenExpired = errors.New("token expired")

func (a App) VerifyUserPassword(ctx context.Context, email, password string) (User, error) {
	if user, err := a.db.UserByEmail(ctx, email); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrCredentialsInvalid
		}
		return nil, err
	} else {
		if b, err := cryptutil.VerifyPassword(password, user.PasswordHash); err != nil {
			return nil, err
		} else if !b {
			return nil, ErrCredentialsInvalid
		}
		if user, err := a.UserByID(ctx, user.ID); err != nil {
			return nil, err
		} else {
			return user, nil
		}
	}
}

func (a App) CreateAccessToken(ctx context.Context, userID int32) (string, error) {
	if token, err := a.db.InsertAccessToken(ctx, db.InsertAccessTokenParams{
		ID:       GenerateRandomString(accessTokenLength),
		Validity: accessTokenValiditiy,
		UserID:   userID,
	}); err != nil {
		return "", err
	} else {
		return token.ID, nil
	}
}

func (a App) VerifyAccessToken(ctx context.Context, accessToken string) (User, error) {
	token, err := a.db.AccessTokenById(ctx, accessToken)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, ErrTokenInvalid
	} else if err != nil {
		return nil, err
	}
	if time.Now().After(token.Expires.Time) {
		return nil, ErrTokenExpired
	}
	if user, err := a.UserByID(ctx, token.UserID); err != nil {
		return nil, err
	} else {
		return user, nil
	}
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
