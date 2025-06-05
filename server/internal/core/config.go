package core

type Config struct {
	Password   PasswordConfig  `koanf:"password"`
	BaseDir    string          `koanf:"basedir"`
	Permisison UserPermissions `koanf:"permission"`
}

type PasswordConfig struct {
	Length  int `koanf:"length"`
	Lower   int `koanf:"lower"`
	Upper   int `koanf:"upper"`
	Numeric int `koanf:"numeric"`
	Symbols int `koanf:"symbols"`
}
