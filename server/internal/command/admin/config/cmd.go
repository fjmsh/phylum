package config

import (
	"fmt"
	"os"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/argon2"
	"codeberg.org/shroff/phylum/server/internal/auth/crypt/pbkdf2"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Config Options",
	}
	cmd.AddCommand([]*cobra.Command{
		setupArgon2Command(),
		setupPBKDF2Command(),
	}...)

	return cmd
}

func setupArgon2Command() *cobra.Command {
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
		src := "test"
		start := time.Now()
		hash, err := a.GenerateEncodedHash(src)
		hashTime := time.Since(start)
		if err != nil {
			fmt.Println("failed to generate hash: " + err.Error())
			os.Exit(1)
		}

		if hashTime.Milliseconds() < 5 {
			fmt.Printf("Took %dus\n", hashTime.Microseconds())
		} else {
			fmt.Printf("Took %dms\n", hashTime.Milliseconds())
		}

		if hashTime.Milliseconds() < 300 {
			fmt.Println("Ideally, password hashing should take at least 300ms")
		}

		if ok, err := crypt.VerifyPasswordHash(src, hash); err != nil {
			fmt.Println("error while verifying password hash: " + err.Error())
			os.Exit(1)
		} else if ok {
			fmt.Println("Verification Successful")
		} else {
			fmt.Println("Error: Hash Verification NOT Successful")
			os.Exit(1)
		}
	}
	cmd.Flags().Uint8P("memory", "m", 16, "Memory Cost (Memory required is 2^m KB)")
	cmd.Flags().Uint32P("iterations", "t", 4, "Iterations")
	cmd.Flags().Uint8P("parallelism", "p", 2, "Parallelism")
	cmd.Flags().Uint32P("salt-len", "s", 32, "Salt Length (in Bytes)")
	cmd.Flags().Uint32P("key-len", "k", 32, "Key Length (in Bytes)")
	return cmd
}

func setupPBKDF2Command() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "pbkdf2",
		Short: "PBKDF2 Key Generation Timing",
	}
	cmd.Run = func(cmd *cobra.Command, args []string) {
		fn, _ := cmd.Flags().GetString("hash-function")
		n, _ := cmd.Flags().GetInt("iterations")
		s, _ := cmd.Flags().GetUint32("salt-len")
		k, _ := cmd.Flags().GetInt("key-len")
		a, err := pbkdf2.New(pbkdf2.Config{
			Function:   fn,
			Iterations: n,
			Salt:       s,
			Key:        k,
		})
		if err != nil {
			fmt.Println("failed to generate hash: " + err.Error())
			os.Exit(1)
		}
		src := string("test")

		start := time.Now()
		hash, err := a.GenerateEncodedHash(src)
		hashTime := time.Since(start)
		if err != nil {
			fmt.Println("failed to generate hash: " + err.Error())
			os.Exit(1)
		}

		if hashTime.Milliseconds() < 5 {
			fmt.Printf("Took %dus\n", hashTime.Microseconds())
		} else {
			fmt.Printf("Took %dms\n", hashTime.Milliseconds())
		}

		if hashTime.Milliseconds() < 300 {
			fmt.Println("Ideally, password hashing should take at least 300ms")
		}

		if ok, err := crypt.VerifyPasswordHash(src, hash); err != nil {
			fmt.Println("error while verifying password hash: " + err.Error())
			os.Exit(1)
		} else if ok {
			fmt.Println("Verification Successful")
		} else {
			fmt.Println("Error: Hash Verification NOT Successful")
			os.Exit(1)
		}
	}
	cmd.Flags().String("hash-function", "sha-256", "Hash Function")
	cmd.Flags().IntP("iterations", "n", 500000, "Iterations")
	cmd.Flags().Uint32P("salt-len", "s", 32, "Salt Length (in Bytes)")
	cmd.Flags().IntP("key-len", "k", 32, "Key Length (in Bytes)")
	return cmd
}
