package user

type Config struct {
	Password   PasswordConfig `koanf:"password"`
	BaseDir    string         `koanf:"basedir"`
	Permisison Permission     `koanf:"permission"`
}

type PasswordConfig struct {
}
