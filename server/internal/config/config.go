package config

import (
	"embed"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/command/serve"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"codeberg.org/shroff/phylum/server/internal/steve"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/providers/env"
	"github.com/knadh/koanf/providers/file"
	"github.com/knadh/koanf/providers/posflag"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/v2"
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)

//go:embed config.defaults.yml
var defaultConfig embed.FS

type Config struct {
	Debug   bool           `koanf:"debug"`
	DB      db.Config      `koanf:"db"`
	Storage storage.Config `koanf:"storage"`
	Server  serve.Config   `koanf:"server"`
	Mail    mail.Config    `koanf:"mail"`
	Core    core.Config    `koanf:"core"`
	Auth    auth.Config    `koanf:"auth"`
	Steve   steve.Config   `koanf:"jobs"`
}

func LoadEnv() *koanf.Koanf {
	k := koanf.New(".")
	k.Load(env.Provider("PHYLUM_", ".", func(s string) string {
		return strings.Replace(strings.ToLower(
			strings.TrimPrefix(s, "PHYLUM_")), "_", ".", -1)
	}), nil)
	return k
}

func LoadFlags(cmd *cobra.Command) (*koanf.Koanf, error) {
	k := koanf.New(".")
	err := k.Load(posflag.ProviderWithFlag(cmd.Flags(), ".", nil, func(f *pflag.Flag) (string, interface{}) {
		if !f.Changed {
			return "", ""
		}
		k, v := strings.ReplaceAll(f.Name, "_", "."), posflag.FlagVal(cmd.Flags(), f)
		return k, v
	}), nil)
	return k, err
}

func LoadFile(path string) (*koanf.Koanf, error) {
	k := koanf.New(".")
	err := k.Load(file.Provider(path), yaml.Parser())
	return k, err
}

func LoadDefault() (*koanf.Koanf, error) {
	if bytes, err := defaultConfig.ReadFile("config.defaults.yml"); err != nil {
		return nil, err
	} else {
		k := koanf.New(".")
		err := k.Load(rawbytes.Provider(bytes), yaml.Parser())
		return k, err
	}
}
