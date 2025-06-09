package crypt

type Config struct {
	Hash   string       `koanf:"hash"`
	Argon2 Argon2Config `koanf:"argon2"`
}

type Argon2Config struct {
	Memory      uint32 `koanf:"memory"`
	Iterations  uint32 `koanf:"iterations"`
	Parallelism uint8  `koanf:"parallelism"`
	Salt        uint32 `koanf:"salt"`
	Key         uint32 `koanf:"key"`
}
