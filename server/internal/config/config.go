package config

import (
	"embed"
	"errors"
	"os"
	"strings"

	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/providers/env"
	"github.com/knadh/koanf/providers/file"
	"github.com/knadh/koanf/providers/posflag"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/v2"
	"github.com/rogpeppe/go-internal/renameio"
	"github.com/spf13/cobra"
	"github.com/spf13/pflag"
)

//go:embed config.defaults.yml
var defaultConfig embed.FS
var configFile string

var Full *koanf.Koanf
var defaults = koanf.New(".")
var ymlConfig = koanf.New(".")
var overrides = koanf.New(".")

var needsSetup = true

func Initialize(cmd *cobra.Command) error {
	// Default config
	var err error
	defaults, err = LoadDefaults()
	if err != nil {
		return errors.New("Failed to load default config: " + err.Error())
	}

	// config.yml
	configFile, _ = cmd.Flags().GetString("config")
	ymlConfig, err = LoadFile(configFile)
	needsSetup = errors.Is(err, os.ErrNotExist)

	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return errors.New("failed to load config: " + err.Error())
	}

	// Overrides - Flags and env vars
	overrides, err = LoadOverrides(cmd)
	if err != nil {
		return errors.New("Failed to load flags: " + err.Error())
	}

	Full = defaults.Copy()
	Full.Merge(ymlConfig)
	Full.Merge(overrides)

	return nil
}

func NeedsSetup() bool {
	return needsSetup
}

func WriteConfig(cfg *koanf.Koanf) error {
	bytes, err := cfg.Marshal(yaml.Parser())
	if err != nil {
		return errors.New("failed to marshal config: " + err.Error())
	}
	return renameio.WriteFile(configFile, bytes)
}

func MergeSub(path string, cfg *koanf.Koanf) *koanf.Koanf {
	sub := defaults.Cut(path)
	sub.Merge(ymlConfig.Cut(path))
	sub.Merge(cfg)
	sub.Merge(overrides.Cut(path))
	return sub
}

func MergeWithYaml(cfg *koanf.Koanf, path string) *koanf.Koanf {
	result := ymlConfig.Copy()
	result.MergeAt(cfg, path)
	return result
}

func HasOverrides(path string, cfg *koanf.Koanf) (overriden []string) {
	overrides := overrides.Cut(path)
	for k := range cfg.All() {
		if overrides.Get(k) != nil {
			overriden = append(overriden, k)
		}
	}
	return overriden
}

func Overrides(paths []string) map[string]any {
	result := koanf.New(".")
	for _, p := range paths {
		o := overrides.Cut(p)
		if len(o.Keys()) != 0 {
			result.MergeAt(o, p)
		}
	}
	result.Keys()
	for _, k := range result.Keys() {
		if strings.Contains(k, "client_secret") || strings.Contains(k, "password") {
			result.Delete(k)
		}
	}
	return result.Raw()
}

func LoadOverrides(cmd *cobra.Command) (*koanf.Koanf, error) {
	k := koanf.New(".")
	err := k.Load(posflag.ProviderWithFlag(cmd.Flags(), ".", nil, func(f *pflag.Flag) (string, interface{}) {
		if !f.Changed {
			return "", ""
		}
		k, v := f.Name, posflag.FlagVal(cmd.Flags(), f)
		return k, v
	}), nil)

	k.Load(env.Provider("PHYLUM_", "__", func(s string) string {
		return strings.ToLower(strings.TrimPrefix(s, "PHYLUM_"))
	}), nil)

	return k, err
}

func LoadFile(path string) (*koanf.Koanf, error) {
	k := koanf.New(".")
	err := k.Load(file.Provider(path), yaml.Parser())
	return k, err
}

func LoadDefaults() (*koanf.Koanf, error) {
	if bytes, err := defaultConfig.ReadFile("config.defaults.yml"); err != nil {
		return nil, err
	} else {
		k := koanf.New(".")
		err := k.Load(rawbytes.Provider(bytes), yaml.Parser())
		return k, err
	}
}
