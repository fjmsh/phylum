package setup

import (
	"errors"
	"net/http"
	"os"
	"syscall"

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
	DB struct {
		db.Config
		Wipe bool `json:"wipe"`
	} `koanf:"db" json:"db"`
	Mail mail.Config `koanf:"mail,omitempty" json:"mail"`
	Auth auth.Config `koanf:"auth" json:"auth"`
	Core core.Config `koanf:"core,omitempty"`
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

	inCfg := koanf.New(".")
	inCfg.Load(structs.Provider(params.Config, "koanf"), nil)
	fullCfg := config.MergeSub("", inCfg)

	var dbConfig db.Config
	var mailConfig mail.Config
	var authConfig auth.Config
	var coreConfig core.Config
	fullCfg.Unmarshal("db", &dbConfig)
	fullCfg.Unmarshal("mail", &mailConfig)
	fullCfg.Unmarshal("auth", &authConfig)
	fullCfg.Unmarshal("core", &coreConfig)

	defer func() {
		syscall.Kill(os.Getpid(), syscall.SIGINT)
	}()

	logger := zerolog.Logger{}
	if params.Config.DB.Wipe {
		dbConfig.NoMigrate = true
	}

	if pool, err := db.Initialize(c.Request.Context(), dbConfig, &logger); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize DB",
			"details": err.Error(),
		})
		return
	} else if params.Config.DB.Wipe {
		if err := db.ResetSchema(c.Request.Context(), pool); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed to Reset DB Schema",
				"details": err.Error(),
			})

		} else if schemaInfo, err := db.GetSchemaInfo(c.Request.Context(), pool); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed get DB Schema Info",
				"details": err.Error(),
			})
		} else if err := schemaInfo.MigrateTo(c.Request.Context(), schemaInfo.LatestVersion); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed migrate DB Schema",
				"details": err.Error(),
			})
		}
	}
	d := db.Get(c.Request.Context())

	if err := core.Initialize(d, coreConfig); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize core",
			"details": err.Error(),
		})
		return
	}
	if err := auth.Initialize(authConfig, logger); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to initialize auth",
			"details": err.Error(),
		})
		return
	}
	if params.User.Password != "" && !auth.PasswordBackendSupportsUpdate() {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Attempting to set password when backend doesn't support it",
		})
		return
	}
	if m, err := mail.CreateMailer(mailConfig, logger); err != nil {
		if !errors.Is(err, mail.ErrEmailNotConfigured) {
			c.JSON(http.StatusOK, gin.H{
				"success": false,
				"error":   "Failed to initialize mail",
				"details": err.Error(),
			})
			return
		}
	} else {
		mail.SetDefaultMailer(m)
	}

	err = d.RunInTx(func(db db.TxHandler) error {
		if user, err := core.CreateUser(db, params.User.Email, params.User.Name, false); err != nil {
			return err
		} else {
			if params.User.Password != "" {
				// Already checked that the password backend supports update
				if err := auth.UpdateUserPassword(db, params.User.Email, params.User.Password); err != nil {
					return err
				}
			}
			core.SetUserPermissions(db, user.ID, []core.UserPermission{"*"})
		}
		return nil
	})
	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"success": false,
			"error":   "Failed to create user",
			"details": err.Error(),
		})
		return
	}

	config.WriteConfig(inCfg)

	c.JSON(http.StatusOK, gin.H{
		"success": true,
	})

}
