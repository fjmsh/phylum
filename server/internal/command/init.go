package command

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"syscall"

	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

var reader = bufio.NewReader(os.Stdin)

func setupInitCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:  "init",
		Args: cobra.NoArgs,
	}

	cmd.Run = func(cmd *cobra.Command, args []string) {
		logger := zerolog.Ctx(cmd.Context())
		configFile, _ := cmd.Flags().GetString("config-file")
		if _, err := os.Stat(configFile); err == nil {
			// config file already exists. What to do?!
			fmt.Println("Config file already exists")

			clear := readBool("Server config already exists. Are you sure you want wipe it and start over?", false, nil, "", false)
			if !clear {
				fatal("Aborting...")
			}
		} else if !errors.Is(err, os.ErrNotExist) {
			fatal("Failed to open config file: " + err.Error())
		}

		// Default config
		k := koanf.New(".")
		if kDefault, err := config.LoadDefault(); err != nil {
			fatal("Failed to load default config: " + err.Error())
		} else {
			k.Merge(kDefault)
		}

		// Flags
		if kFlags, err := config.LoadFlags(cmd); err != nil {
			fatal("Failed to load flags: " + err.Error())
		} else {
			k.Merge(kFlags)
		}

		// Environment variables
		k.Merge(config.LoadEnv())
		var defaultConfig config.Config
		k.UnmarshalWithConf("", &defaultConfig, koanf.UnmarshalConf{Tag: "koanf"})
		k.All()

		fmt.Println()
		fmt.Println("DATABASE CONFIG")
		readDBConfig(defaultConfig.DB, *logger)
		fmt.Println("Database Connected")
	}

	return cmd
}

func readDBConfig(defaultConfig db.Config, logger zerolog.Logger) *koanf.Koanf {
	cfg := koanf.New(".")
	readString("    Host", defaultConfig.Host, cfg, "host", true)
	readInt("    Port", defaultConfig.Port, cfg, "port", true)
	readString(" DB Name", defaultConfig.Name, cfg, "name", true)
	readString("Username", defaultConfig.User, cfg, "user", true)
	readSecret("Password", cfg, "password")

	var config db.Config
	if err := cfg.Unmarshal("", &config); err != nil {
		panic(err)
	}
	if _, err := db.Initialize(context.Background(), config, logger); err != nil {
		fmt.Println("Unable to connect to db with the provided info")
		fmt.Println(err.Error())

		if readBool("Try again?", true, nil, "", false) {
			return readDBConfig(config, logger)
		} else {
			os.Exit(1)
		}
	}

	return cfg
}

func fatal(err any) {
	fmt.Println(err)
	os.Exit(1)
}

func handleInput[T any](input string, convert func(string) T, def T, cfg *koanf.Koanf, key string, storeDefault bool) (value T) {
	value = def
	if input != "" {
		value = convert(input)
	}
	if cfg != nil && key != "" && (storeDefault || input != "") {
		cfg.Set(key, value)
	}
	return value
}

func readString(title string, def string, cfg *koanf.Koanf, key string, storeDefault bool) string {
	prompt := fmt.Sprintf("%s [%s]", title, def)
	in := readValidString(prompt, nil)
	convert := func(in string) string { return in }
	return handleInput(in, convert, def, cfg, key, storeDefault)
}

func readInt(title string, def int, cfg *koanf.Koanf, key string, storeDefault bool) int {
	prompt := fmt.Sprintf("%s [%d]", title, def)
	in := readValidString(prompt, func(input string) bool {
		if input == "" {
			return true
		}
		_, err := strconv.Atoi(input)
		return err == nil
	})

	convert := func(in string) int { value, _ := strconv.Atoi(in); return value }
	return handleInput(in, convert, def, cfg, key, storeDefault)
}

func readBool(title string, def bool, cfg *koanf.Koanf, key string, storeDefault bool) bool {
	defString := "y/N"
	if def {
		defString = "Y/n"
	}

	prompt := fmt.Sprintf("%s [%s]", title, defString)
	in := readValidString(prompt, func(input string) bool {
		input = strings.ToLower(input)
		return input == "" || input == "y" || input == "yes" || input == "n" || input == "no"
	})
	convert := func(in string) bool { return in == "y" || in == "yes" }
	return handleInput(strings.ToLower(in), convert, def, cfg, key, storeDefault)
}

func readValidString(prompt string, validate func(string) bool) string {
	for {
		fmt.Print(prompt + ": ")
		if in, err := reader.ReadString('\n'); err != nil {
			if errors.Is(err, io.EOF) {
				fmt.Println("end of input")
				os.Exit(1)
			} else {
				panic(fmt.Sprint("Error while reading secret: ", err.Error()))
			}
		} else {
			fmt.Scanln("%s", &in)
			in = strings.TrimSpace(in)
			if validate == nil || validate(in) {
				return in
			}
			fmt.Println("Invalid input")
		}
	}
}

func readSecret(title string, cfg *koanf.Koanf, key string) string {
	fmt.Print(title, ": ")
	bytes, err := term.ReadPassword(syscall.Stdin)
	os.Stdout.WriteString("\n")
	if err != nil {
		if errors.Is(err, io.EOF) {
			fmt.Println("end of input")
			os.Exit(1)
		} else {
			panic(fmt.Sprint("Error while reading secret: ", err.Error()))
		}
	}
	secret := string(bytes)
	if cfg != nil && key != "" {
		cfg.Set(key, secret)
	}
	return secret
}
