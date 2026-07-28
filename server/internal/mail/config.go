package mail

type Config struct {
	Enabled              bool       `koanf:"enabled" json:"enabled"`
	SMTP                 SMTPConfig `koanf:"smtp" json:"smtp"`
	From                 FromConfig `koanf:"from" json:"from"`
	Instance             string     `koanf:"instance" json:"instance"`
	ConnectionCheckFatal bool       `koanf:"connection_check_fatal" json:"connection_check_fatal"`
}

type SMTPConfig struct {
	Host     string `koanf:"host" json:"host"`
	Port     int    `koanf:"port" json:"port"`
	Username string `koanf:"username" json:"username"`
	Password string `koanf:"password" json:"password"`
}

type FromConfig struct {
	Name  string `koanf:"name" json:"name"`
	Email string `koanf:"email" json:"email"`
}
