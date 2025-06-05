package command

import (
	"github.com/shroff/phylum/server/internal/command/serve"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/shroff/phylum/server/internal/core/user"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/shroff/phylum/server/internal/mail"
)

type Config struct {
	Debug   bool           `koanf:"debug"`
	DB      db.Config      `koanf:"db"`
	Storage storage.Config `koanf:"storage"`
	Server  serve.Config   `koanf:"server"`
	Mail    mail.Config    `koanf:"mail"`
	User    user.Config    `koanf:"user"`
	Crypt   crypt.Config   `koanf:"crypt"`
}
