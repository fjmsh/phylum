package steve

type Config struct {
	Workers int `koanf:"workers"`
	Timeout int `koanf:"timeout"`
}
