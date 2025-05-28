package crypt

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"

	"golang.org/x/crypto/argon2"
)

func generateArgon2(password string) (string, error) {
	p := Cfg.Argon2
	fmt.Printf("%+v\n", p)
	salt, err := generateRandomBytes(p.Salt)
	if err != nil {
		return "", err
	}

	key := argon2.IDKey([]byte(password), salt, p.Iterations, p.Memory, p.Parallelism, p.Key)

	b64Salt := base64.RawStdEncoding.EncodeToString(salt)
	b64Hash := base64.RawStdEncoding.EncodeToString(key)

	return fmt.Sprintf("$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s", argon2.Version, p.Memory, p.Iterations, p.Parallelism, b64Salt, b64Hash), nil
}

func verifyArgon2(password string, hashParts []string) (bool, error) {
	p, salt, storedHash, err := decodeHash(hashParts)
	if err != nil {
		return false, err
	}

	// Derive the key from the provided password using the same parameters.
	computedHash := argon2.IDKey([]byte(password), salt, p.Iterations, p.Memory, p.Parallelism, p.Key)

	if subtle.ConstantTimeCompare(storedHash, computedHash) == 1 {
		return true, nil
	}
	return false, nil
}

func decodeHash(hashParts []string) (p Argon2Config, salt, hash []byte, err error) {
	if len(hashParts) != 4 {
		err = errors.New("incorrect hash format for argon2id")
		return
	}

	var version int
	_, err = fmt.Sscanf(hashParts[0], "v=%d", &version)
	if err != nil {
		return
	}
	if version != argon2.Version {
		err = errors.New("unrecognized version of argon2")
		return
	}

	_, err = fmt.Sscanf(hashParts[1], "m=%d,t=%d,p=%d", &p.Memory, &p.Iterations, &p.Parallelism)
	if err != nil {
		return
	}

	salt, err = base64.RawStdEncoding.Strict().DecodeString(hashParts[2])
	if err != nil {
		return
	}
	p.Salt = uint32(len(salt))

	hash, err = base64.RawStdEncoding.Strict().DecodeString(hashParts[3])
	if err != nil {
		return
	}
	p.Key = uint32(len(hash))

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
