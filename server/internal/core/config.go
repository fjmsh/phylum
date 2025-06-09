package core

type Config struct {
	BaseDir    string          `koanf:"basedir"`
	Permisison UserPermissions `koanf:"permission"`
}
