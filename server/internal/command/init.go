package command

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"regexp"
	"slices"
	"strconv"
	"strings"
	"syscall"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/pbkdf2"
	"codeberg.org/shroff/phylum/server/internal/auth/ldap"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/knadh/koanf/parsers/yaml"
	"github.com/knadh/koanf/providers/structs"
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

		if exists, err := config.ConfigFileExists(cmd); err != nil {
			fatal("Failed to open config file: " + err.Error())

		} else if exists {
			fmt.Println("Server config already exists")

			clear := readBool("Do you want to wipe it and start over?", false, nil, "", false)
			if !clear {
				fatal("Aborting...")
			}
		}

		if err := config.Initialize(cmd); err != nil {
			fatal("failed to load config: " + err.Error())
		}
		var defaultConfig Config
		config.Full.UnmarshalWithConf("", &defaultConfig, koanf.UnmarshalConf{Tag: "koanf"})

		cfg := koanf.New(".")

		fmt.Println()
		fmt.Println()
		fmt.Println("DATABASE CONFIG")
		db := readDBConfig(defaultConfig.DB, *logger)
		cfg.MergeAt(db, "db")

		fmt.Println()
		fmt.Println()
		fmt.Println("EMAIL CONFIG")
		fmt.Println("Email is required for self-serve password reset, " +
			"inviting users, sending share notifications, and sending passwordless login links")
		hasEmailConfig := false
		if readBool("Configure Email?", true, nil, "", false) {
			if mail := readMailConfig(defaultConfig.Mail, *logger); mail != nil {
				hasEmailConfig = true
				cfg.MergeAt(mail, "mail")
			} else {
				fmt.Println("Skipping email config...")
			}
		} else {
			fmt.Println("Skipping email config...")
		}

		fmt.Println()
		fmt.Println()
		fmt.Println("AUTH CONFIG")
		auth := readAuthConfig(defaultConfig.Auth, hasEmailConfig, *logger)
		cfg.MergeAt(auth, "auth")

		if b, err := cfg.Marshal(yaml.Parser()); err != nil {
			fmt.Println("failed to marshal config: ", err.Error())
		} else {
			fmt.Println(string(b))
		}

	}

	return cmd
}

func readDBConfig(defaultConfig db.Config, logger zerolog.Logger) *koanf.Koanf {
	cfg := koanf.New(".")
	readString("    Host", defaultConfig.Host, cfg, "host", true)
	readInt("    Port", defaultConfig.Port, cfg, "port", true)
	readString(" DB Name", defaultConfig.Name, cfg, "name", true)
	readString("Username", defaultConfig.User, cfg, "user", true)
	readSecret("Password", defaultConfig.Password, cfg, "password")
	fmt.Println()

	var config db.Config
	if err := cfg.Unmarshal("", &config); err != nil {
		panic(err)
	}
	if _, err := db.Initialize(context.Background(), config, &logger); err != nil {
		fmt.Println("Unable to connect to db with the provided info")
		fmt.Println(err.Error())

		if readBool("Try again?", true, nil, "", false) {
			return readDBConfig(config, logger)
		} else {
			os.Exit(1)
		}
	}

	fmt.Println("Database Connected")
	return cfg
}

func readMailConfig(defaultConfig mail.Config, logger zerolog.Logger) *koanf.Koanf {
	cfg := koanf.New(".")
	readString("   SMTP Host", defaultConfig.SMTP.Host, cfg, "smtp.host", true)
	readInt("   SMTP Port", defaultConfig.SMTP.Port, cfg, "smtp.port", true)
	smtpUsername := readString("    Username", defaultConfig.SMTP.Username, cfg, "smtp.username", true)
	readSecret("    Password", defaultConfig.SMTP.Password, cfg, "smtp.password")
	readString("  Email Name", defaultConfig.From.Name, cfg, "from.name", true)
	defaultFromEmail := defaultConfig.From.Email
	if defaultFromEmail == "" {
		defaultFromEmail = smtpUsername
	}
	readString("  Email Addr", defaultFromEmail, cfg, "from.email", true)
	readString("Instance URL", defaultConfig.Instance, cfg, "instance", true)
	fmt.Println()

	var config mail.Config
	if err := cfg.Unmarshal("", &config); err != nil {
		panic(err)
	}
	var err error
	var mailer mail.Mailer
	if mailer, err = mail.CreateMailer(config, logger); err != nil {
		fmt.Println("Unable to connect to the mail server")
		fmt.Println(err.Error())

		if readBool("Try again?", true, nil, "", false) {
			return readMailConfig(config, logger)
		} else {
			return nil
		}
	}

	if readBool("Do you want to send a test email to validate the config?", true, nil, "", false) {
		for {
			addr := readValidString("Recipient Email Address", nil)
			if err := mailer.SendTestEmail(addr); err != nil {
				fmt.Println("Unable to send test email: " + err.Error())
				if readBool("Try again?", true, nil, "", false) {
					continue
				} else {
					break
				}
			} else {
				fmt.Println("Test email sent! (make sure to check spam if you don't see it in your inbox)")
				if !readBool("Send another one?", false, nil, "", false) {
					break
				}
			}
		}
	}

	return cfg
}

func readAuthConfig(config auth.Config, hasEmailConfig bool, logger zerolog.Logger) *koanf.Koanf {
	cfg := koanf.New(".")

	oidcLoginEnabled := false
	if readBool("Add OpenID Connect login provider?", false, nil, "", false) {
		fmt.Println()

		openidCfg := koanf.New(".")
		name := readString("Provider Name", "", openidCfg, "name", false)
		readString("Issuer URL", "", openidCfg, "issuer_url", true)
		readString("Client ID", "", openidCfg, "client_id", true)
		readSecret("Client Secret", "", openidCfg, "client_secret")

		re := regexp.MustCompile(`[^a-z0-9]+`)
		id := re.ReplaceAllString(strings.ToLower(name), "-")
		cfg.MergeAt(openidCfg, "openid.clients."+id)

		oidcLoginEnabled = true
	}

	// Password Login
	passwordLoginEnabled := readBool("Enable password login?", true, nil, "", false)
	if passwordLoginEnabled {
		passwordBackend := readOption("Password Login Backend", []string{"crypt", "ldap"}, "crypt", cfg, "password.backend", true)
		switch passwordBackend {
		case "crypt":
			crypt := readCryptConfig(config.Password.Crypt)
			cfg.MergeAt(crypt, "crypt")
		case "ldap":
			ldap := readLDAPConfig(config.Password.LDAP, logger)
			cfg.MergeAt(ldap, "ldap")
		default:
			fatal("Unsupported Backend: " + passwordBackend)
		}
		fmt.Println()

		if passwordBackend == "crypt" && hasEmailConfig {
		} else {
			fmt.Println("Skipping password reset (unspported)...")
		}

		if passwordBackend == "crypt" {
			requirements := koanf.New(".")
			fmt.Println()
			if readBool("Set minimum password requirements?", true, nil, "", false) {
				readInt("Minimum Password Length", config.Password.Requirements.Length, requirements, "length", true)
				readInt("Minimum Upper Case Characters", config.Password.Requirements.Upper, requirements, "upper", true)
				readInt("Minimum Lower Case Characters", config.Password.Requirements.Lower, requirements, "lower", true)
				readInt("Minimum Numeric Characters", config.Password.Requirements.Numeric, requirements, "numeric", true)
				readInt("Minimum Symbols", config.Password.Requirements.Symbols, requirements, "symbols", true)
			} else {
				requirements.Load(structs.Provider(&auth.PasswordRequirements{}, "koanf"), nil)
			}
			cfg.MergeAt(requirements, "password.requirements")
		} else {
			fmt.Println("Skipping minimum requirements *(unsupported)...")
		}
	} else {
		cfg.Set("password.backend", "none")
	}

	// Passwordless login
	passwordlessLoginEnabled := false
	if hasEmailConfig {
		passwordlessLoginEnabled = readBool("Allow passwordless login via email?", config.MagicLinks, cfg, "magic_links", true)
	}

	if !passwordlessLoginEnabled && !passwordLoginEnabled && !oidcLoginEnabled {
		if readBool("No login methods configured. Configure again?", true, nil, "", false) {
			return readAuthConfig(config, hasEmailConfig, logger)
		} else {
			os.Exit(1)
		}
	}

	return cfg
}

func readCryptConfig(defaultConfig crypt.Config) *koanf.Koanf {
	cfg := koanf.New(".")
	kdf := readOption("Select KDF", []string{"argon2", "pbkdf2"}, defaultConfig.KDF, cfg, "kdf", true)

	fmt.Println()
	fmt.Println(`As a rule of thumb, you should aim to take at least 300 - 500ms, up to 1s for key
generation in order to have a good balance of security, cost, and convenience
(or at least, lack of inconvenience).`)
	fmt.Println()

	switch kdf {
	case "argon2":
		fmt.Println("Argon2 Configuration")
		if readBool("Would you like more information about how to configuration Argon2 parameters?", true, nil, "", false) {

			fmt.Println(`1. Start by setting memory (m) and parallelism (p) to the highest numbers you can
   afford on your machine, considering:
	- Memory requirement is exponentially related to the memory factor (m), so
	    m=16 means 64MB, m=17 means 128MB, m=18 means 256MB
    - You need to leave headroom for other processes
	- There may be multiple simultaneous hashes

2. Increase the number of iterations(t) until you reach the desired time.

3. If you are already at t=1 and it's taking too long then either increase
   p or decrease m`)
			fmt.Println()
		}
		argon2 := readArgon2Config(defaultConfig.Argon2)
		cfg.MergeAt(argon2, "argon2")
	case "pbkdf2":
		fmt.Println("PBKDF2 Configuration")
		pbkdf2 := readPBKDF2Config(defaultConfig.PBKDF2)
		cfg.MergeAt(pbkdf2, "pbkdf2")
	default:
		fatal("Unrecognized KDF: " + kdf)
	}
	return cfg
}

func readArgon2Config(config argon2.Config) *koanf.Koanf {
	cfg := koanf.New(".")

	readInt("Memory Factor (m)", int(config.Memory), cfg, "memory", true)
	readInt("Iterations (t)", int(config.Iterations), cfg, "iterations", true)
	readInt("Parallelism (p)", int(config.Parallelism), cfg, "parallelism", true)
	fmt.Println()

	cfg.Unmarshal("", &config)
	src := "test"
	start := time.Now()
	_, err := argon2.New(config).GenerateEncodedHash(src)
	hashTime := time.Since(start)
	if err != nil {
		fatal("failed to generate hash: " + err.Error())
	}

	if hashTime.Milliseconds() < 5 {
		fmt.Printf("Took %dus\n", hashTime.Microseconds())
	} else {
		fmt.Printf("Took %dms\n", hashTime.Milliseconds())
	}

	acceptable := true
	if hashTime.Milliseconds() > 1000 {
		fmt.Println("Looks like that took a long time.")
		acceptable = false
	} else if hashTime.Milliseconds() < 300 {
		fmt.Println("Ideally, password hashing should take at least 300ms")
		acceptable = false
	}
	fmt.Println()

	if !readBool("Keep Argon2 config?", acceptable, nil, "", false) {
		cfg.Merge(readArgon2Config(config))
	}
	return cfg
}

func readPBKDF2Config(config pbkdf2.Config) *koanf.Koanf {
	cfg := koanf.New(".")

	readOption("Hash Function", []string{"sha-1", "sha-256", "sha-512"}, config.Function, cfg, "function", true)
	readInt("Iterations", int(config.Iterations), cfg, "iterations", true)
	fmt.Println()

	cfg.Unmarshal("", &config)
	src := "test"
	start := time.Now()
	kdf, err := pbkdf2.New(config)
	if err != nil {
		fatal("failed to create PBKDF: " + err.Error())
	}
	_, err = kdf.GenerateEncodedHash(src)
	hashTime := time.Since(start)
	if err != nil {
		fatal("failed to generate hash: " + err.Error())
	}

	if hashTime.Milliseconds() < 5 {
		fmt.Printf("Took %dus\n", hashTime.Microseconds())
	} else {
		fmt.Printf("Took %dms\n", hashTime.Milliseconds())
	}

	acceptable := true
	if hashTime.Milliseconds() > 1000 {
		fmt.Println("Looks like that took a long time.")
		acceptable = false
	} else if hashTime.Milliseconds() < 300 {
		fmt.Println("Ideally, password hashing should take at least 300ms")
		acceptable = false
	}
	fmt.Println()

	if !readBool("Keep PBKDF2 config?", acceptable, nil, "", false) {
		cfg.Merge(readPBKDF2Config(config))
	}
	return cfg
}

func readLDAPConfig(config ldap.Config, logger zerolog.Logger) *koanf.Koanf {
	cfg := koanf.New(".")

	fmt.Println("LDAP Config")
	readString("Server URL", config.URL, cfg, "url", true)
	readBool("Use STARTTLS?", config.StartTLS, cfg, "starttls", true)
	fmt.Println()
	fmt.Println(`In order to authenticate using LDAP, we first need to find out the
Distinguished Name (DN) of the user using the provided email address.`)
	fmt.Println()
	useTemplate := readBool("Would you like to use a template to construct the LDAP DN?", false, nil, "", false)
	if useTemplate {
		readString("DN Template", "cn={email},ou=people,dc=example,dc=com", cfg, "dn_template", true)
	} else {
		fmt.Println("DN Lookup")
		readString("Bind DN", "cn=phylumbind,ou=people,dc=example,dc=com", cfg, "search.bind_dn", true)
		readSecret("Bind DN Password", "", cfg, "search.bind_password")
		readString("Base DN", "dc=example,dc=com", cfg, "search.base_dn", true)
		readString("Filter Template", "(mail={email})", cfg, "search.filter_template", true)
	}
	fmt.Println()

	fmt.Println("Test the configuration?")
	cfg.Unmarshal("", &config)
	if auth, err := ldap.NewAuth(config, logger); err != nil {
		fmt.Println("Error: " + err.Error())
		if readBool("Keep config?", false, nil, "", false) {
			return cfg
		} else {
			cfg.Merge(readLDAPConfig(config, logger))
		}
	} else if _, err := auth.VerifyUserPassword(nil, "email", "password"); err != nil {
		fmt.Println("Error: " + err.Error())
		if readBool("Keep config?", false, nil, "", false) {
			return cfg
		} else {
			cfg.Merge(readLDAPConfig(config, logger))
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
	return handleInput(in, convert, def, cfg, key, storeDefault)
}

func readOption(title string, options []string, def string, cfg *koanf.Koanf, key string, storeDefault bool) string {
	prompt := fmt.Sprintf("%s (%s)[%s]", title, strings.Join(options, "/"), def)
	in := readValidString(prompt, func(input string) bool {
		return input == "" || slices.Index(options, strings.ToLower(input)) != -1
	})
	convert := func(in string) string { return strings.ToLower(in) }
	return handleInput(in, convert, def, cfg, key, storeDefault)
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

func readSecret(title string, def string, cfg *koanf.Koanf, key string) string {
	if def == "" {
		fmt.Print(title, ": ")
	} else {
		fmt.Print(title, "[unchanged]: ")
	}
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
	if secret == "" {
		secret = def
	}
	if cfg != nil && key != "" {
		cfg.Set(key, secret)
	}
	return secret
}
