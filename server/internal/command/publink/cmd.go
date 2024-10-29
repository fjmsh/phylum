package publink

import (
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

func SetupCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "publink",
		Short: "Publink Management",
	}
	flags := cmd.PersistentFlags()
	flags.Bool("auto-migrate", true, "Automatically migrate database schema")
	viper.BindPFlag("auto_migrate", flags.Lookup("auto-migrate"))

	flags.StringP("user", "u", "phylum", "User")

	cmd.AddCommand(
		setupCreateCommand(),
	)

	return cmd
}
