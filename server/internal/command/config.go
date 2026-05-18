package command

import (
	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/command/serve"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
)

type Config struct {
	Debug   bool           `koanf:"debug"`
	DB      db.Config      `koanf:"db" json:"db"`
	Storage storage.Config `koanf:"storage"`
	Server  serve.Config   `koanf:"server"`
	Mail    mail.Config    `koanf:"mail" json:"mail"`
	Core    core.Config    `koanf:"core"`
	Auth    auth.Config    `koanf:"auth" json:"auth"`
	Steve   steve.Config   `koanf:"jobs"`
}
