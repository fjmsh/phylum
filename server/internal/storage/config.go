package storage

type Config struct {
	Root   string                 `koanf:"root"`
	Temp   string                 `koanf:"temp"`
	Mounts map[string]MountConfig `koanf:"mounts"`
}

type MountConfig struct {
	MountPoint string            `koanf:"mount_point"`
	Driver     string            `koanf:"driver"`
	Params     map[string]string `koanf:"params"`
}
