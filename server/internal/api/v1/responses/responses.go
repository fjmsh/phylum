package responses

import (
	"encoding/json"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type Ancestor struct {
	ID             uuid.UUID `json:"id"`
	Name           string    `json:"name"`
	UserPermission int32     `json:"user_permission"`
}

type Resource struct {
	ID                   uuid.UUID       `json:"id"`
	Parent               pgtype.UUID     `json:"parent"`
	Name                 string          `json:"name"`
	Dir                  bool            `json:"dir"`
	Created              int64           `json:"created"`
	Modified             int64           `json:"modified"`
	Deleted              int64           `json:"deleted"`
	InheritedPermissions json.RawMessage `json:"inherited_permissions,omitempty"`
	Grants               json.RawMessage `json:"grants"`
	Versions             json.RawMessage `json:"versions"`
	Links                json.RawMessage `json:"publinks"`
}

type ResourceFull struct {
	Resource  Resource   `json:"resource"`
	Ancestors []Ancestor `json:"ancestors"`
	Children  []Resource `json:"children"`
}

type User struct {
	ID    int32  `json:"id"`
	Email string `json:"email"`
	Name  string `json:"name"`
}

type LoggedInUser struct {
	User
	Home        pgtype.UUID          `json:"home"`
	Permissions core.UserPermissions `json:"permissions"`
}

type Publink struct {
	ID          string    `json:"id"`
	Created     time.Time `json:"created"`
	Root        uuid.UUID `json:"root"`
	Accessed    int32     `json:"accessed"`
	AccessLimit int32     `json:"access_limit"`
	Protected   bool      `json:"protected"`
	Expires     int64     `json:"expires"`
}

type Login struct {
	AccessToken string `json:"access_token"`
	Bootstrap
}

type Bookmark struct {
	ResourceID uuid.UUID `json:"resource_id"`
	Name       string    `json:"name"`
	Dir        bool      `json:"dir"`
	Created    int64     `json:"created"`
}

type Bootstrap struct {
	User      LoggedInUser `json:"user"`
	Bookmarks []Bookmark   `json:"bookmarks"`
	Users     []User       `json:"users"`
	Until     int          `json:"until"`
	Clear     bool         `json:"clear"`
}
