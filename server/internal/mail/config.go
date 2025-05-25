package mail

type Config struct {
	SMTP     SMTPConfig `koanf:"smtp"`
	From     FromConfig `koanf:"from"`
	Instance string     `koanf:"instance"`
}

type SMTPConfig struct {
	Host     string `koanf:"host"`
	Port     int    `koanf:"port"`
	Username string `koanf:"username"`
	Password string `koanf:"password"`
}

type FromConfig struct {
	Name  string `koanf:"name"`
	Email string `koanf:"email"`
}
