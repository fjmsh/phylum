package keys

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/spf13/cobra"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "keys",
		Short: "Manager API Keys",
	}

	cmd.AddCommand(
		setupGenerateCommand(),
		setupListCommand(),
	)

	return cmd
}

func setupGenerateCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "generate",
		Short: "Generate New API Key/Token",
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				fmt.Println("unable to generate API key: user not specified")
				os.Exit(1)
			}
			validity, _ := cmd.Flags().GetDuration("validity")
			description, _ := cmd.Flags().GetString("description")
			reader := bufio.NewReader(os.Stdin)
			if description == "" {
				fmt.Print("Description: ")
				if val, err := reader.ReadString('\n'); err != nil {
					fmt.Println("failed to read scopes: " + err.Error())
					os.Exit(1)
				} else if len(strings.TrimSpace(val)) == 0 {
					description = "Generated via CLI"
				} else {

				}
			}
			var scopes []string
			if len(scopes) == 0 {
				name, _ := cmd.Flags().GetString("name")
				if name == "" {
					fmt.Print("Comma-separated scopes [*]: ")
					if val, err := reader.ReadString('\n'); err != nil {
						fmt.Println("failed to read scopes: " + err.Error())
						os.Exit(1)
					} else if len(strings.TrimSpace(val)) == 0 {
						scopes = []string{"*"}
					} else {
						scopes = strings.Split(val, ",")
						for i, s := range scopes {
							scopes[i] = strings.TrimSpace(s)
						}
					}
				}
			}

			if err := db.Get(context.Background()).RunInTx(func(db db.TxHandler) error {
				if token, _ := cmd.Flags().GetBool("token"); token {
					if token, err := auth.GenerateAPIToken(db, u.ID, validity, description, scopes); err != nil {
						return err
					} else {
						fmt.Println(token)
						return nil
					}
				} else {
					if id, key, err := auth.GenerateAPIKey(db, u.ID, validity, description, scopes); err != nil {
						return err
					} else {
						fmt.Println("Key ID:", id)
						fmt.Println("   Key:", key)
						return nil
					}
				}
			}); err != nil {
				fmt.Println("unable to generate API key: " + err.Error())
				os.Exit(1)
			}
		},
	}

	cmd.Flags().BoolP("token", "t", false, "Generate API token instead of ID:Key pair")
	cmd.Flags().Duration("validity", time.Duration(0), "Validity of API Key (0 means never)")
	cmd.Flags().String("description", "", "Validity of API Key (0 means never)")
	cmd.Flags().StringSlice("scopes", []string{}, "Scopes")
	return cmd
}

func setupListCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "list",
		Short: "List API Keys",
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				fmt.Println("unable to list API Keys: user not specified")
				os.Exit(1)
			}
			keys, err := auth.ListAPIKeys(db.Get(context.Background()), u.ID)
			if err != nil {
				fmt.Println("unable to list API keys: " + err.Error())
			}
			for _, k := range keys {
				fmt.Println(k.ID.String() + " [" + k.Description + "]")
				fmt.Println("Created:", k.Created.Format(time.DateTime))
				expires := "Never"
				if k.Expires.Valid {
					expires = k.Expires.Time.Format(time.DateTime)
					if k.Expires.Time.Before(time.Now()) {
						expires += " [X]"
					}
				}
				fmt.Println("Expires:", expires)
				fmt.Println(" Scopes:", strings.Join(k.Scopes, ", "))
				fmt.Println()
			}
		},
	}

	return cmd
}
