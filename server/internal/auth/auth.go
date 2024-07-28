package auth

import (
	"context"
	"errors"
	"time"
	"unsafe"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/cryptutil"
	"github.com/shroff/phylum/server/internal/sql"
	"github.com/shroff/phylum/server/internal/user"
	"github.com/sirupsen/logrus"
	"golang.org/x/exp/rand"
)

const accessTokenLength = 16

var accessTokenValiditiy = pgtype.Interval{
	Days:  30,
	Valid: true,
}

var ErrInvalidUsernamePassword = errors.New("invalid username or password")
var ErrAccessTokenExpired = errors.New("access token expired")

type Manager struct {
	db          *sql.DbHandler
	userManager *user.Manager
}

func NewManager(db *sql.DbHandler, userManager *user.Manager) (*Manager, error) {
	return &Manager{db: db, userManager: userManager}, nil
}

func (m Manager) CreateAccessToken(username, password, deviceInfo string) (string, error) {
	if user, err := m.userManager.FindUser(context.Background(), username); err != nil {
		if err == pgx.ErrNoRows {
			return "", ErrInvalidUsernamePassword
		}
		logrus.Info(err)
		return "", err
	} else {
		if b, err := cryptutil.VerifyPassword(password, user.PasswordHash); err != nil {
			logrus.Info(err.Error())
			return "", err
		} else if !b {
			return "", ErrInvalidUsernamePassword
		}
	}
	accessToken := GenerateRandomString(accessTokenLength)
	if err := m.db.Queries().InsertAccessToken(context.Background(), sql.InsertAccessTokenParams{
		ID:       accessToken,
		Validity: accessTokenValiditiy,
		Username: username,
	}); err != nil {
		return "", err
	}
	return accessToken, nil
}

func (m Manager) VerifyAccessToken(accessToken string) (string, error) {
	token, err := m.db.Queries().AccessTokenById(context.Background(), accessToken)
	if err != nil {
		return "", err
	}
	if time.Now().After(token.Expires.Time) {
		return "", ErrAccessTokenExpired
	}
	return token.Username, nil
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
