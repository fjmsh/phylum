package user

import (
	"net/http"

	"codeberg.org/shroff/phylum/server/internal/api/authenticator"
	"codeberg.org/shroff/phylum/server/internal/api/v1/responses"
	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgtype"
)

type grantParams struct {
	Email       string   `json:"user_email" form:"email"`
	ID          int32    `json:"user_id" form:"user_id"`
	Permissions []string `json:"permissions" form:"permissions" binding:"required"`
}

func handlePermissionsUpdateRequest(c *gin.Context) {
	var params grantParams
	err := c.ShouldBindJSON(&params)
	if err != nil {
		err = c.BindQuery(&params)
		if err != nil {
			panic(errInvalidParams)
		}
	}
	if (params.Email == "" && params.ID <= 0) || (params.Email != "" && params.ID > 0) {
		panic(errInvalidParams)
	}

	auth := authenticator.GetAuth(c)
	var u core.User
	if err := db.RunInTx(c.Request.Context(), func(db db.TxHandler) error {
		if params.ID <= 0 {
			if u, err = core.UserByEmail(db, params.Email); err != nil {
				return err
			}
		} else {
			if u, err = core.UserByID(db, params.ID); err != nil {
				return err
			}
		}

		grant := make(map[core.UserPrivilege]bool)
		revoke := make(map[core.UserPrivilege]bool)
		for _, p := range params.Permissions {
			grant[p] = true
		}
		for _, p := range u.Privileges {
			if _, ok := grant[p]; ok {
				delete(grant, p)
			} else {
				revoke[p] = true
			}
		}
		for p := range grant {
			if !auth.UserPrivileges().HasPermission(p) {
				return core.NewError(http.StatusBadRequest, "insufficient_permissions", "Cannot grant permission "+p)
			}
		}

		for p := range revoke {
			if !auth.UserPrivileges().HasPermission(p) {
				return core.NewError(http.StatusBadRequest, "insufficient_permissions", "Cannot revoke permission "+p)
			}
		}

		core.SetUserPrivileges(db, params.ID, params.Permissions)
		return nil
	}); err != nil {
		panic(err)
	}

	home := pgtype.UUID{}
	if auth.UserPrivileges().HasPermission(core.UserPrivilegeFilesRead) {
		home = u.Home
	}
	c.JSON(200, responses.FullUser{
		User: responses.User{
			ID:    u.ID,
			Email: u.Email,
			Name:  u.Name,
		},
		Permissions: params.Permissions,
		Home:        home,
	})
}
