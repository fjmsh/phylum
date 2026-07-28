package argon2

import (
	"crypto/rand"
	"crypto/subtle"
	"encoding/base64"
	"errors"
	"fmt"
	"math"
	"strings"

	"golang.org/x/crypto/argon2"
)

type Config struct {
	Memory      uint8  `koanf:"memory" json:"memory"`
	Iterations  uint32 `koanf:"iterations" json:"iterations"`
	Parallelism uint8  `koanf:"parallelism" json:"parallelism"`
	Salt        uint32 `koanf:"salt" json:"salt"`
	Key         uint32 `koanf:"key" json:"key"`
}

type argon struct {
	cfg Config
}

func New(cfg Config) *argon {
	return &argon{cfg: cfg}
}

func (a argon) GenerateEncodedHash(password string) (string, error) {
	p := a.cfg
	salt, err := generateRandomBytes(p.Salt)
	if err != nil {
		return "", err
	}

	key := argon2.IDKey([]byte(password), salt, p.Iterations, 1<<p.Memory, p.Parallelism, p.Key)

	b64Salt := base64.RawStdEncoding.EncodeToString(salt)
	b64Hash := base64.RawStdEncoding.EncodeToString(key)

	return fmt.Sprintf("$argon2id$v=%d$m=%d,t=%d,p=%d$%s$%s", argon2.Version, p.Memory, p.Iterations, p.Parallelism, b64Salt, b64Hash), nil
}

func VerifyEncodedHash(password string, hashParts []string) (bool, error) {
	if hashParts[0] != "argon2id" {
		return false, errors.New("argon2 variant unsupported: " + hashParts[0])
	}
	p, salt, storedHash, err := decodeHash(hashParts[1:])
	if err != nil {
		return false, err
	}

	// Derive the key from the provided password using the same parameters.
	computedHash := argon2.IDKey([]byte(password), salt, p.Iterations, 1<<p.Memory, p.Parallelism, p.Key)

	if subtle.ConstantTimeCompare(storedHash, computedHash) == 1 {
		return true, nil
	}
	return false, nil
}

func decodeHash(hashParts []string) (p Config, salt, hash []byte, err error) {
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
		if strings.Contains(err.Error(), "unsigned integer overflow") {
			var mExp float64
			_, err = fmt.Sscanf(hashParts[1], "m=%f,t=%d,p=%d", &mExp, &p.Iterations, &p.Parallelism)
			if err != nil {
				return
			}
			p.Memory = uint8(math.Round(math.Log2(mExp)))
		} else {
			return
		}
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
