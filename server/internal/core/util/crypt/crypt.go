package crypt

import (
	"errors"
	"strings"
)

var Cfg Config

func Verify(password, encodedHash string) (bool, error) {
	parts := strings.Split(encodedHash, "$")
	parts = parts[1:]

	if parts[0] == "argon2id" {
		return verifyArgon2(password, parts[1:])
	}
	index := strings.Index(encodedHash[1:], "$")
	if index < 0 {
	}
	return false, errors.New("unrecognized encoded hash algorithm: " + parts[0])
}

func Generate(password string) (string, error) {
	if Cfg.Hash == "argon2" {
		return generateArgon2(password)
	}
	return "", errors.New("unrecognized hash algorithm: " + Cfg.Hash)
}
