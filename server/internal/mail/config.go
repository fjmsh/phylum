package mail

type Config struct {
	Enabled              bool       `koanf:"enabled" json:"enabled"`
	SMTP                 SMTPConfig `koanf:"smtp,omitempty" json:"smtp"`
	From                 FromConfig `koanf:"from,omitempty" json:"from"`
	Instance             string     `koanf:"instance,omitempty" json:"instance"`
	ConnectionCheckFatal bool       `koanf:"connection_check_fatal,omitempty" json:"connection_check_fatal"`
}

type SMTPConfig struct {
	Host     string `koanf:"host,omitempty" json:"host"`
	Port     int    `koanf:"port,omitempty" json:"port"`
	Username string `koanf:"username,omitempty" json:"username"`
	Password string `koanf:"password,omitempty" json:"password"`
}

type FromConfig struct {
	Name  string `koanf:"name,omitempty" json:"name"`
	Email string `koanf:"email,omitempty" json:"email"`
}
