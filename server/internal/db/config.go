package db

type Config struct {
	Host      string `koanf:"host,omitempty" json:"host"`
	Port      int    `koanf:"port,omitempty" json:"port"`
	Name      string `koanf:"name,omitempty" json:"name"`
	User      string `koanf:"user,omitempty" json:"user"`
	Password  string `koanf:"password,omitempty" json:"password"`
	NoMigrate bool   `koanf:"nomigrate,omitempty"`
	Trace     bool   `koanf:"trace,omitempty"`
}
