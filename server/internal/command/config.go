package command

import (
	"codeberg.org/shroff/phylum/server/internal/command/serve"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/crypt"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"codeberg.org/shroff/phylum/server/internal/storage"
)

type Config struct {
	Debug   bool           `koanf:"debug"`
	DB      db.Config      `koanf:"db"`
	Storage storage.Config `koanf:"storage"`
	Server  serve.Config   `koanf:"server"`
	Mail    mail.Config    `koanf:"mail"`
	User    core.Config    `koanf:"user"`
	Crypt   crypt.Config   `koanf:"crypt"`
}
