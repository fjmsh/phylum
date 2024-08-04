package app

import (
	"context"
	"errors"
	"time"
	"unsafe"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/sirupsen/logrus"
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

func (a App) VerifyUserPassword(ctx context.Context, username, password string) (int32, error) {
	if user, err := a.Db.Queries().UserByUsername(context.Background(), username); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return 0, ErrCredentialsInvalid
		}
		logrus.Info(err)
		return 0, err
	} else {
		if b, err := cryptutil.VerifyPassword(password, user.PasswordHash); err != nil {
			logrus.Warn(err.Error())
			return 0, err
		} else if !b {
			return 0, ErrCredentialsInvalid
		}
		return user.ID, nil
	}
}

func (a App) CreateAccessToken(username, password string) (sql.AccessToken, error) {
	if userID, err := a.VerifyUserPassword(context.Background(), username, password); err != nil {
		return sql.AccessToken{}, err
	} else {
		if token, err := a.Db.Queries().InsertAccessToken(context.Background(), sql.InsertAccessTokenParams{
			ID:       GenerateRandomString(accessTokenLength),
			Validity: accessTokenValiditiy,
			UserID:   userID,
		}); err != nil {
			return sql.AccessToken{}, err
		} else {
			return token, nil
		}
	}
}

func (a App) VerifyAccessToken(accessToken string) (int32, error) {
	token, err := a.Db.Queries().AccessTokenById(context.Background(), accessToken)
	if errors.Is(err, pgx.ErrNoRows) {
		return 0, ErrTokenInvalid
	} else if err != nil {
		return 0, err
	}
	if time.Now().After(token.Expires.Time) {
		return 0, ErrTokenExpired
	}
	return token.UserID, nil
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
