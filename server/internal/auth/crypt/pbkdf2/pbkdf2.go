package pbkdf2

import (
	"crypto/pbkdf2"
	"crypto/rand"
	"crypto/sha1"
	"crypto/sha256"
	"crypto/sha512"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"hash"
	"strconv"
)

type Config struct {
	Function   string `koanf:"function"`
	Iterations int    `koanf:"iterations"`
	Salt       uint32 `koanf:"salt"`
	Key        int    `koanf:"key"`
}

type pbkdf struct {
	fn  func() hash.Hash
	cfg Config
}

func New(cfg Config) (*pbkdf, error) {
	if fn, err := getHashFunction(cfg.Function); err != nil {
		return nil, err
	} else {
		return &pbkdf{fn: fn, cfg: cfg}, nil
	}
}

func getHashFunction(name string) (func() hash.Hash, error) {
	if name == "sha-1" {
		return sha1.New, nil
	} else if name == "sha-256" {
		return sha256.New, nil
	} else if name == "sha-512" {
		return sha512.New, nil
	} else {
		return nil, errors.New("unsupported hash function: " + name)
	}
}

func (a pbkdf) GenerateEncodedHash(password string) (string, error) {
	p := a.cfg
	salt, err := generateRandomBytes(p.Salt)
	if err != nil {
		return "", err
	}

	key, err := pbkdf2.Key(a.fn, password, salt, a.cfg.Iterations, a.cfg.Key)
	if err != nil {
		return "", err
	}

	b64Salt := base64.RawStdEncoding.EncodeToString(salt)
	b64Hash := base64.RawStdEncoding.EncodeToString(key)

	return fmt.Sprintf("$pbkdf2$%s$%d$%s$%s", a.cfg.Function, p.Iterations, b64Salt, b64Hash), nil
}

func VerifyEncodedHash(password string, hashParts []string) (bool, error) {
	fn, iterations, salt, storedHash, err := decodeHash(hashParts[1:])
	if err != nil {
		return false, err
	}

	// Derive the key from the provided password using the same parameters.
	computedHash, err := pbkdf2.Key(fn, password, salt, iterations, len(storedHash))
	if err != nil {
		return false, err
	}

	if subtle.ConstantTimeCompare(storedHash, computedHash) == 1 {
		return true, nil
	}
	return false, nil
}

func decodeHash(hashParts []string) (fn func() hash.Hash, iterations int, salt, hash []byte, err error) {
	if len(hashParts) != 4 {
		err = errors.New("incorrect hash format for argon2id")
		return
	}

	fn, err = getHashFunction(hashParts[0])
	if err != nil {
		return
	}

	iterations, err = strconv.Atoi(hashParts[1])
	if err != nil {
		return
	}

	salt, err = base64.RawStdEncoding.Strict().DecodeString(hashParts[2])
	if err != nil {
		return
	}

	hash, err = base64.RawStdEncoding.Strict().DecodeString(hashParts[3])
	if err != nil {
		return
	}

	return
}

// Generate a cryptographically secure random salt.
func generateRandomBytes(n uint32) ([]byte, error) {
	b := make([]byte, n)
	_, err := rand.Read(b)
	if err != nil {
		return nil, err
	}

	return b, nil
}
