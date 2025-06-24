package core

type Config struct {
	User UserConfig `koanf:"user"`
}

type UserConfig struct {
	BaseDir    string          `koanf:"basedir"`
	Permisison UserPermissions `koanf:"permission"`
}
