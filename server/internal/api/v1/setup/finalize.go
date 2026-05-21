package setup

import (
	"net/http"
	"os"
	"syscall"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/knadh/koanf/providers/structs"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

type finalizeParams struct {
	Config configOverrides `json:"config"`
	User   userConfig      `json:"user"`
}

type configOverrides struct {
	DB   db.Config   `koanf:"db" json:"db"`
	Mail mail.Config `koanf:"mail,omitempty" json:"mail"`
	Auth auth.Config `koanf:"auth" json:"auth"`
}

type userConfig struct {
	Email    string `json:"email"`
	Name     string `json:"name"`
	Password string `json:"password"`
}

func handleFinalize(c *gin.Context) {
	var params finalizeParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		panic(errInvalidParams)
	}

	paramsCfg := koanf.New(".")
	paramsCfg.Load(structs.Provider(params.Config, "koanf"), nil)
	paramsCfg.Print()

	if _, err := db.Initialize(c.Request.Context(), params.Config.DB, &zerolog.Logger{}); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize DB",
			"details": err.Error(),
		})
		return
	}
	d := db.Get(c.Request.Context())
	if users, err := core.ListUsers(d, 0); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to list users",
			"details": err.Error(),
		})
		return
	} else if len(users) != 0 {
		// c.JSON(http.StatusOK, gin.H{
		// 	"success": false,
		// 	"error":   "Database not empty",
		// })
		// return
	}

	// d.RunInTx(func(db db.TxHandler) error {
	// 	if _, err := core.CreateUser(db, params.User.Email, params.User.Name, false); err != nil {
	// 		return err
	// 	}
	// 	if params.User.Password != "" {
	// 		return auth.UpdateUserPassword(db, params.User.Email, params.User.Password)
	// 	}
	// 	return nil
	// })

	config.WriteConfig(paramsCfg)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
	})
	t := time.NewTimer(100 * time.Millisecond)
	go func() {
		<-t.C
		binary, _ := os.Executable()
		syscall.Exec(binary, os.Args, os.Environ())
	}()

}
