package setup

import (
	"io"
	"net/http"
	"os"
	"syscall"

	"codeberg.org/shroff/phylum/server/internal/auth"
	"codeberg.org/shroff/phylum/server/internal/config"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/mail"
	"github.com/gin-gonic/gin"
	"github.com/go-viper/mapstructure/v2"
	"github.com/knadh/koanf/parsers/json"
	"github.com/knadh/koanf/providers/rawbytes"
	"github.com/knadh/koanf/v2"
	"github.com/rs/zerolog"
)

func handleFinalize(c *gin.Context) {
	var params struct {
		Config struct {
			DB   db.Config   `koanf:"db,omitempty" json:"db"`
			Mail mail.Config `koanf:"mail,omitempty" json:"mail"`
			Auth auth.Config `koanf:"auth,omitempty" json:"auth"`
			Core core.Config `koanf:"core,omitempty"`
		} `json:"config"`
		User struct {
			Email    string `json:"email"`
			Name     string `json:"name"`
			Password string `json:"password"`
		} `json:"user"`
		Options struct {
			DB struct {
				Wipe bool `json:"wipe"`
			} `json:"db"`
		}
	}

	k := koanf.New(".")
	if body, err := io.ReadAll(c.Request.Body); err != nil {
		panic(core.NewError(http.StatusBadRequest, "no_request_body", "failed to read request parameters from body: "+err.Error()))
	} else if err := k.Load(rawbytes.Provider(body), json.Parser()); err != nil {
		panic(core.NewError(http.StatusBadRequest, "parse_failed", "failed to parse request parameters from body: "+err.Error()))
	} else if err := k.UnmarshalWithConf("", &params, koanf.UnmarshalConf{DecoderConfig: &mapstructure.DecoderConfig{ErrorUnused: true}}); err != nil {
		panic(core.NewError(http.StatusBadRequest, "validate_failed", "failed to validate request parameters from body: "+err.Error()))
	}

	cfg := config.MergeSub("", k.Cut("config"))

	var dbConfig db.Config
	var mailConfig mail.Config
	var authConfig auth.Config
	var coreConfig core.Config
	cfg.Unmarshal("db", &dbConfig)
	cfg.Unmarshal("mail", &mailConfig)
	cfg.Unmarshal("auth", &authConfig)
	cfg.Unmarshal("core", &coreConfig)
	cfg.Print()

	var err error
	defer func() {
		syscall.Kill(os.Getpid(), syscall.SIGINT)
	}()

	logger := zerolog.Logger{}
	if params.Options.DB.Wipe {
		dbConfig.NoMigrate = true
	}

	if pool, err := db.Initialize(c.Request.Context(), dbConfig, &logger); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"error": gin.H{
				"msg":     "Failed to initialize DB",
				"details": err.Error(),
			},
		})
		return
	} else if params.Options.DB.Wipe {
		if err := db.ResetSchema(c.Request.Context(), pool); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"error": gin.H{
					"msg":     "Failed to Reset DB Schema",
					"details": err.Error(),
				},
			})

		} else if schemaInfo, err := db.GetSchemaInfo(c.Request.Context(), pool); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"error": gin.H{
					"msg":     "Failed get DB Schema Info",
					"details": err.Error(),
				},
			})
		} else if err := schemaInfo.MigrateTo(c.Request.Context(), schemaInfo.LatestVersion); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"error": gin.H{
					"msg":     "Failed migrate DB Schema",
					"details": err.Error(),
				},
			})
		}
	}
	d := db.Get(c.Request.Context())

	if err := core.Initialize(d, coreConfig); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"error": gin.H{
				"msg":     "Failed to initialize core",
				"details": err.Error(),
			},
		})
		return
	}
	if err := auth.Initialize(authConfig, logger); err != nil {
		c.JSON(http.StatusOK, gin.H{
			"error": gin.H{
				"msg":     "Failed to initialize auth",
				"details": err.Error(),
			},
		})
		return
	}
	if params.User.Password != "" && !auth.Get().PasswordBackendSupportsUpdate() {
		c.JSON(http.StatusOK, gin.H{
			"error": gin.H{
				"msg": "Attempting to set password when backend doesn't support it",
			},
		})
		return
	}
	m := mail.CreateMailer(mailConfig, logger)
	mail.SetDefaultMailer(m)
	if m.Enabled() && mailConfig.ConnectionCheckFatal {
		if err := m.CheckConnection(); err != nil {
			c.JSON(http.StatusOK, gin.H{
				"error": gin.H{
					"msg":     "Failed to connect to SMTP server",
					"details": err.Error(),
				},
			})
		}
	}

	err = d.RunInTx(func(db db.TxHandler) error {
		if user, err := core.CreateUser(db, params.User.Email, params.User.Name, false); err != nil {
			return err
		} else {
			if params.User.Password != "" {
				// Already checked that the password backend supports update
				if err := auth.Get().UpdateUserPassword(db, params.User.Email, params.User.Password); err != nil {
					return err
				}
			}
			core.SetUserPermissions(db, user.ID, []core.UserPermission{"*"})
		}
		return nil
	})
	if err != nil {
		c.JSON(http.StatusOK, gin.H{
			"error": gin.H{
				"msg":     "Failed to create user",
				"details": err.Error(),
			},
		})
		return
	}

	config.WriteConfig(k.Cut("config"))

	c.JSON(http.StatusOK, gin.H{
		"success": true,
	})

}
