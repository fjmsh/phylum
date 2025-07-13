package config

import (
	"fmt"
	"os"
	"syscall"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"github.com/spf13/cobra"
	"golang.org/x/term"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Config Options",
	}
	cmd.AddCommand([]*cobra.Command{
		setupArgon2ProfileCommand(),
	}...)

	return cmd
}

func setupArgon2ProfileCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "argon2",
		Short: "Argon2 Key Generation Timing",
		Long: `Time argon2 key generation with the given parameters.

As a rule of thumb, you can aim to take at least 300 - 500ms, up to 1s for key
generation in order to have a good balance of security, cost, and convenience
(or at least, lack of inconvenience).

1. Start by setting m and p to the highest numbers you can afford, considering:
    - You need to leave headroom for other processes
	- There may be multiple simultaneous hashes

2. Increase t until you reach the desired time.

3. If you are already at t=1 and it's taking too long then either increase
   p or decrease m
   
Please keep in mind that while this is an expensive operation, it will only
occur at login, and not for every request because API keys use a different
hashing scheme.

Please also note that inceasing m will require exponentially more memory.
 - m=16 = 64MB (minimum recommended)
 - m=17 = 128MB
 - m=18 = 256MB`,
	}
	cmd.Run = func(cmd *cobra.Command, args []string) {
		os.Stdout.WriteString("Input: ")
		bytes, err := term.ReadPassword(syscall.Stdin)
		os.Stdout.WriteString("\n")
		if err != nil {
			fmt.Println("unable to read input: " + err.Error())

		}

		m, _ := cmd.Flags().GetUint8("memory")
		t, _ := cmd.Flags().GetUint32("iterations")
		p, _ := cmd.Flags().GetUint8("parallelism")
		s, _ := cmd.Flags().GetUint32("salt-len")
		k, _ := cmd.Flags().GetUint32("key-len")
		a := argon2.New(argon2.Config{
			Memory:      m,
			Iterations:  t,
			Parallelism: p,
			Salt:        s,
			Key:         k,
		})
		src := string(bytes)

		start := time.Now()
		hash, err := a.GenerateEncodedHash(src)
		hashTime := time.Since(start)
		if err != nil {
			fmt.Println("failed to generate hash: " + err.Error())
			os.Exit(1)
		}

		fmt.Println(hash)
		fmt.Printf("%dms\n", hashTime.Milliseconds())
		if hashTime.Milliseconds() < 300 {
			fmt.Println("Use these params at your own risk. Password hashing should take at least 300ms")
		}
	}
	cmd.Flags().Uint8P("memory", "m", 18, "Memory Cost (Memory required is 2^m KB)")
	cmd.Flags().Uint32P("iterations", "t", 4, "Iterations")
	cmd.Flags().Uint8P("parallelism", "p", 4, "Parallelism")
	cmd.Flags().Uint32P("salt-len", "s", 32, "Salt Length (in Bytes)")
	cmd.Flags().Uint32P("key-len", "k", 32, "Key Length (in Bytes)")
	return cmd
}
