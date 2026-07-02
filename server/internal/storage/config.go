package storage

type Config struct {
	Root   string                 `koanf:"root"`
	Temp   string                 `koanf:"temp"`
	Mounts map[string]MountConfig `koanf:"mounts"`
}

type MountConfig struct {
	MountPoints []string          `koanf:"mount_points"`
	Driver      string            `koanf:"driver"`
	Params      map[string]string `koanf:"params"`
}
