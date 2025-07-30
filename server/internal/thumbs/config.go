package thumbs

type Config struct {
	Dir     string `koanf:"dir"`
	Quality uint8  `koanf:"quality"`
}
