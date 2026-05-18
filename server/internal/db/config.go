package db

type Config struct {
	Host      string `koanf:"host" json:"host"`
	Port      int    `koanf:"port" json:"port"`
	Name      string `koanf:"name" json:"name"`
	User      string `koanf:"user" json:"user"`
	Password  string `koanf:"password" json:"password"`
	NoMigrate bool   `koanf:"nomigrate,omitempty"`
	Trace     bool   `koanf:"trace,omitempty"`
}
