package main

import (
	"codeberg.org/shroff/phylum/server/internal/command"
	"github.com/davidbyttow/govips/v2/vips"
)

func main() {
	vips.Startup(nil)
	defer vips.Shutdown()
	command.SetupCommand()
}
