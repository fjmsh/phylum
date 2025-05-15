package db

type Config struct {
	Host      string `koanf:"host"`
	Port      int    `koanf:"port"`
	DBName    string `koanf:"dbname"`
	User      string `koanf:"user"`
	Password  string `koanf:"password"`
	NoMigrate bool   `koanf:"nomigrate"`
	Trace     bool   `koanf:"trace"`
}
