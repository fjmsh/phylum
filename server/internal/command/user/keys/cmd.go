package keys

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"sort"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/command/common"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5/pgtype"
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
		setupRevokeCommand(),
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
			expires := pgtype.Timestamptz{}
			if validity != 0 {
				expires.Time = time.Now().Add(validity)
				expires.Valid = true
			}
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
				if a, err := auth.NewAuth(auth.NewSUAuth(*u), expires, scopes); err != nil {
					return err
				} else if id, key, token, err := auth.GenerateAPIKey(db, a, description); err != nil {
					return err
				} else {
					fmt.Println("Key ID:", id)
					fmt.Println("   Key:", key)
					fmt.Println(" Token:", token)
					return nil
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
			showExpired, _ := cmd.Flags().GetBool("show-expired")
			keys, err := auth.ListAPIKeys(db.Get(context.Background()), u.ID, showExpired)
			sort.Slice(keys, func(i, j int) bool {
				a := keys[i]
				b := keys[j]
				if a.LastUsed.Time == b.LastUsed.Time {
					return a.Created.After(b.Created)
				}
				return a.LastUsed.Time > b.LastUsed.Time
			})
			if err != nil {
				fmt.Println("unable to list API keys: " + err.Error())
			}
			for _, k := range keys {
				expires := "Never"
				if k.Expires.Valid {
					expires = k.Expires.Time.Format(time.DateTime)
					if k.Expires.Time.Before(time.Now()) {
						expires += " [X]"
					}
				}
				fmt.Println(k.ID + " [" + k.Description + "]")
				fmt.Println("  Created:", k.Created.Format(time.DateTime))
				fmt.Println("  Expires:", expires)
				fmt.Println("   Scopes:", strings.Join(k.Scopes, ", "))
				lastUsed := "Never"
				if k.LastUsed.Time != 0 {
					t := time.Unix(k.LastUsed.Time, 0).Format(time.DateTime)
					lastUsed = fmt.Sprintf("%s by %s at %s", t, k.LastUsed.Device, k.LastUsed.IP)
				}
				fmt.Println("Last Used:", lastUsed)
				fmt.Println()
			}
		},
	}

	cmd.Flags().BoolP("show-expired", "x", false, "Show Expired Keys")

	return cmd
}

func setupRevokeCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "revoke <id>...",
		Short: "Revoke API Keys",
		Args:  cobra.MinimumNArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			u := common.User(cmd)
			if u == nil {
				fmt.Println("unable to revoke API Keys: user not specified")
				os.Exit(1)
			}
			delete, _ := cmd.Flags().GetBool("delete")
			err := db.RunInTx(context.Background(), func(db db.TxHandler) error {
				for _, k := range args {
					if err := auth.RevokeAPIKey(db, u.ID, k, delete); err != nil {
						return err
					}
				}
				return nil
			})
			if err != nil {
				fmt.Println("failed to revoke some keys: " + err.Error())
				os.Exit(1)
			}
		},
	}
	cmd.Flags().Bool("delete", false, "Delete from DB")

	return cmd
}
