package config

import (
	"embed"
	"errors"
	"os"
	"slices"
	"strings"

	"github.com/go-viper/mapstructure/v2"
	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/providers/env"
	"github.com/knadh/koanf/providers/file"
	"github.com/knadh/koanf/providers/posflag"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/providers/structs"
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

type ConfigFieldsUnusedError struct {
	Fields []string
}

func (c ConfigFieldsUnusedError) Error() string {
	return "Found unused config fields: " + strings.Join(c.Fields, ", ")
}

func Initialize[T any](cmd *cobra.Command) (*T, error) {
	// Default config
	var err error
	defaults, err = LoadDefaults[T]()
	if err != nil {
		return nil, errors.New("Failed to load default config: " + err.Error())
	}

	// config.yml
	configFile, _ = cmd.Flags().GetString("config")
	ymlConfig, err = LoadFile[T](configFile)
	needsSetup = errors.Is(err, os.ErrNotExist)

	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return nil, errors.New("failed to load config: " + err.Error())
	}

	// Overrides - Flags and env vars
	overrides, err = LoadOverrides[T](cmd)
	if err != nil {
		return nil, errors.New("Failed to load flags: " + err.Error())
	}

	Full = defaults.Copy()
	Full.Merge(ymlConfig)
	Full.Merge(overrides)

	md := mapstructure.Metadata{}
	cfg := new(T)
	uc := koanf.UnmarshalConf{Tag: "koanf", DecoderConfig: &mapstructure.DecoderConfig{
		WeaklyTypedInput: false,
		Metadata:         &md,
	}}
	if err := Full.UnmarshalWithConf("", cfg, uc); err != nil {
		return nil, err
	}
	unused := slices.DeleteFunc(md.Unused, func(e string) bool {
		return e == "workdir" || e == "config" || e == "image_tag"
	})
	if len(unused) != 0 {
		return cfg, ConfigFieldsUnusedError{Fields: unused}
	}

	return cfg, nil
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

func ConfigMap(path string) map[string]any {
	result := Full.Cut(path)

	for _, k := range result.Keys() {
		if strings.HasSuffix(k, "secret") || strings.HasSuffix(k, "password") {
			result.Set(k, "")
		}
	}

	return map[string]any{
		"config":    result.Raw(),
		"overrides": overrides.Cut(path).Keys(),
	}
}

func ConfigMapWithUpdates(path string, updates *koanf.Koanf) map[string]any {
	overrides := overrides.Cut(path)
	result := defaults.Cut(path)
	result.Merge(ymlConfig.Cut(path))
	result.Merge(updates)
	result.Merge(overrides)

	for _, k := range result.Keys() {
		if strings.HasSuffix(k, "secret") || strings.HasSuffix(k, "password") {
			result.Set(k, "")
		}
	}

	return map[string]any{
		"config":    result.Raw(),
		"overrides": overrides.Cut(path).Keys(),
	}
}

func LoadOverrides[T any](cmd *cobra.Command) (*koanf.Koanf, error) {
	k := koanf.New(".")
	err := k.Load(posflag.ProviderWithFlag(cmd.Flags(), ".", nil, func(f *pflag.Flag) (string, interface{}) {
		if !f.Changed {
			return "", ""
		}
		k, v := f.Name, posflag.FlagVal(cmd.Flags(), f)
		return k, v
	}), nil)
	if err != nil {
		return nil, err
	}

	err = k.Load(env.Provider("PHYLUM_", "__", func(s string) string {
		return strings.ToLower(strings.TrimPrefix(s, "PHYLUM_"))
	}), nil)
	if err != nil {
		return nil, err
	}

	return fixTypes[T](k, true)
}

func LoadFile[T any](path string) (*koanf.Koanf, error) {
	k := koanf.New(".")
	if err := k.Load(file.Provider(path), yaml.Parser()); err != nil {
		return k, err
	}
	return fixTypes[T](k, false)
}

func LoadDefaults[T any]() (*koanf.Koanf, error) {
	if bytes, err := defaultConfig.ReadFile("config.defaults.yml"); err != nil {
		return nil, err
	} else {
		k := koanf.New(".")
		err := k.Load(rawbytes.Provider(bytes), yaml.Parser())
		if err != nil {
			return nil, err
		}
		return fixTypes[T](k, false)
	}
}

func fixTypes[T any](k *koanf.Koanf, weaklyTypedInput bool) (*koanf.Koanf, error) {
	config := new(T)
	uc := koanf.UnmarshalConf{
		DecoderConfig: &mapstructure.DecoderConfig{
			DecodeHook: mapstructure.ComposeDecodeHookFunc(
				mapstructure.StringToTimeDurationHookFunc(),
				mapstructure.TextUnmarshallerHookFunc()),
			Metadata:         nil,
			WeaklyTypedInput: weaklyTypedInput,
		},
	}
	if err := k.UnmarshalWithConf("", config, uc); err != nil {
		return nil, err
	}
	kTyped := koanf.New(".")
	if err := kTyped.Load(structs.Provider(*config, "koanf"), nil); err != nil {
		return nil, err
	}
	for _, key := range k.Keys() {
		k.Set(key, kTyped.Get(key))
	}

	return k, nil
}
