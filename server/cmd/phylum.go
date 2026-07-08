package main

import (
	"codeberg.org/shroff/phylum/server/internal/command"
	"github.com/davidbyttow/govips/v2/vips"
)

func main() {
	vips.LoggingSettings(nil, vips.LogLevelWarning)
	vips.Startup(nil)
	defer vips.Shutdown()
	command.SetupCommand()
}
