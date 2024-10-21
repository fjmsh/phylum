package user

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"strings"

	"golang.org/x/crypto/argon2"
)

type Argon2Params struct {
	salt        uint32
	key         uint32
	memory      uint32
	iterations  uint32
	parallelism uint8
}

func defaultArgon2Params() Argon2Params {
	return Argon2Params{
		salt:        32,
		key:         32,
		memory:      2048,
		iterations:  6,
		parallelism: 4,
	}
}

func generateArgon2EncodedHash(password string, p Argon2Params) (string, error) {
	salt, err := generateRandomBytes(p.salt)
	if err != nil {
		return "", err
	}

	key := argon2.IDKey([]byte(password), salt, p.iterations, p.memory, p.parallelism, p.key)

	b64Salt := base64.RawStdEncoding.EncodeToString(salt)
	b64Hash := base64.RawStdEncoding.EncodeToString(key)

	// Return a string using the standard encoded hash representation.
	return fmt.Sprintf("$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s", argon2.Version, p.memory, p.iterations, p.parallelism, b64Salt, b64Hash), nil
}

func verifyPassword(password, encodedHash string) (bool, error) {
	// Extract the parameters, salt and derived key from the encoded password
	// hash.
	p, salt, hash, err := decodeHash(encodedHash)
	if err != nil {
		return false, err
	}

	// Derive the key from the other password using the same parameters.
	otherHash := argon2.IDKey([]byte(password), salt, p.iterations, p.memory, p.parallelism, p.key)

	// Check that the contents of the hashed passwords are identical. Note
	// that we are using the subtle.ConstantTimeCompare() function for this
	// to help prevent timing attacks.
	if subtle.ConstantTimeCompare(hash, otherHash) == 1 {
		return true, nil
	}
	return false, nil
}

func decodeHash(encodedHash string) (p *Argon2Params, salt, hash []byte, err error) {
	vals := strings.Split(encodedHash, "$")
	if vals[1] != "argon2id" {
		return nil, nil, nil, errors.New("unrecognized hash")
	}

	if len(vals) != 6 {
		return nil, nil, nil, errors.New("incorrect hash format for argon2id")
	}

	var version int
	_, err = fmt.Sscanf(vals[2], "v=%d", &version)
	if err != nil {
		return nil, nil, nil, err
	}
	if version != argon2.Version {
		return nil, nil, nil, errors.New("unrecognized version of argon2")
	}

	p = &Argon2Params{}
	_, err = fmt.Sscanf(vals[3], "m=%d,t=%d,p=%d", &p.memory, &p.iterations, &p.parallelism)
	if err != nil {
		return nil, nil, nil, err
	}

	salt, err = base64.RawStdEncoding.Strict().DecodeString(vals[4])
	if err != nil {
		return nil, nil, nil, err
	}
	p.salt = uint32(len(salt))

	hash, err = base64.RawStdEncoding.Strict().DecodeString(vals[5])
	if err != nil {
		return nil, nil, nil, err
	}
	p.key = uint32(len(hash))

	return p, salt, hash, nil
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
