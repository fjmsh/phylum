package thumbs

type Config struct {
	Size    uint16 `koanf:"size"`
	Format  string `koanf:"format"`
	Quality uint8  `koanf:"quality"`
}
