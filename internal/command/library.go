package command

import (
	"github.com/spf13/cobra"
)

func setupLibraryCommand() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "library",
		Short: "Library Management",
	}
	cmd.AddCommand([]*cobra.Command{
		setupLibraryCreateCommand(),
		setupLibraryDeleteCommand(),
	}...)
	return cmd
}

func setupLibraryCreateCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "create storage-backend owner display-name",
		Short: "Create Library",
		Args:  cobra.ExactArgs(3),
		Run: func(cmd *cobra.Command, args []string) {
			// id := uuid.New()

			// storageName := args[0]
			// storage := storageManager.Find(storageName)
			// if storage == nil {
			// 	logrus.Fatal("Storage not found: " + storageName)
			// }

			// username := args[1]
			// user, err := userManager.FindUser(context.Background(), username)
			// if err != nil {
			// 	logrus.Fatal("User not found: " + username)
			// }
			// name := args[2]
			// if err := libraryManager.Create(context.Background(), id, storageName, user.ID, name); err != nil {
			// 	logrus.Fatal(err)
			// }
			// logrus.Info("Created " + id.String())
		},
	}
}

func setupLibraryDeleteCommand() *cobra.Command {
	return &cobra.Command{
		Use:   "delete id",
		Short: "Delete Library",
		Args:  cobra.ExactArgs(1),
		Run: func(cmd *cobra.Command, args []string) {
			// id, err := uuid.Parse(args[0])
			// if err != nil {
			// 	logrus.Fatal("Not an ID: " + args[0])
			// }
			// if err := libraryManager.Delete(context.Background(), id); err != nil {
			// 	logrus.Fatal(err)
			// }
		},
	}
}
