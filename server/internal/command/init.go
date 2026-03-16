package command

import (
	"bufio"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"strings"
	"syscall"

	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/v2"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

var reader = bufio.NewReader(os.Stdin)
var cfg = map[string]any{}

func setupInitCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:  "init",
		Args: cobra.NoArgs,
	}

	cmd.Run = func(cmd *cobra.Command, args []string) {
		configFile, _ := cmd.Flags().GetString("config-file")
		if _, err := os.Stat(configFile); err == nil {
			// config file already exists. What to do?!
			fmt.Println("Config file already exists")

			clear := readBool("Server config already exists. Are you sure you want wipe it and start over?", false, "", false)
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

		readDBConfig(defaultConfig.DB)
		p := yaml.Parser()
		if y, err := p.Marshal(toNestedMap(cfg)); err != nil {
			fmt.Println(err.Error())
		} else {
			fmt.Println(string(y))
		}
		// k.Print()
	}

	return cmd
}

func toNestedMap(in map[string]any) map[string]any {
	out := make(map[string]any)
	for k, v := range in {
		path := strings.Split(k, ".")
		m := out
		for _, p := range path[:len(path)-1] {
			var mm map[string]any
			if existing, ok := m[p]; !ok {
				mm = make(map[string]any)
				m[p] = mm
			} else if mm, ok = existing.(map[string]any); !ok {
				panic(fmt.Sprintf("key `%s` in `%s` is not a map", p, k))
			}
			m = mm
		}
		m[path[len(path)-1]] = v
	}
	return out
}

func readDBConfig(config db.Config) {
	host := readString("DB Host", config.Host, "db.host", true)
	port := readInt("DB Host", config.Port, "db.port", true)
	dbName := readString("DB Name", config.Name, "db.name", true)
	user := readString("DB User", config.User, "db.user", true)
	password := readSecret("DB Password", "db.password")
	config = db.Config{
		Host:     host,
		Port:     port,
		Name:     dbName,
		User:     user,
		Password: password,
	}
}

func fatal(err any) {
	fmt.Println(err)
	os.Exit(1)
}

func handleInput[T any](input string, convert func(string) T, def T, cfgKey string, persistDefault bool) (value T) {
	value = def
	if input != "" {
		value = convert(input)
	}
	if cfgKey != "" && (persistDefault || input != "") {
		cfg[cfgKey] = value
	}
	return value
}

func readString(title string, def string, cfgKey string, persistDefault bool) string {
	prompt := fmt.Sprintf("%s [%s]", title, def)
	response := readValidString(prompt, nil)
	return handleInput(response, func(in string) string { return in }, def, cfgKey, persistDefault)
}

func readInt(title string, def int, cfgKey string, persistDefault bool) int {
	prompt := fmt.Sprintf("%s [%d]", title, def)
	response := readValidString(prompt, func(input string) bool {
		if input == "" {
			return true
		}
		_, err := strconv.Atoi(input)
		return err == nil
	})

	return handleInput(response, func(in string) int { value, _ := strconv.Atoi(in); return value }, def, cfgKey, persistDefault)
}

func readBool(title string, def bool, cfgKey string, persistDefault bool) bool {
	defString := "y/N"
	if def {
		defString = "Y/n"
	}

	prompt := fmt.Sprintf("%s [%s]", title, defString)
	response := readValidString(prompt, func(input string) bool {
		input = strings.ToLower(input)
		return input == "" || input == "y" || input == "yes" || input == "n" || input == "no"
	})
	return handleInput(strings.ToLower(response), func(in string) bool { return in == "y" || in == "yes" }, def, cfgKey, persistDefault)
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

func readSecret(title string, cfgKey string) string {
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
	cfg[cfgKey] = secret
	return secret
}
