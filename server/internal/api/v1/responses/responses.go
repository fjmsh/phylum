package responses

import (
	"encoding/json"
	"time"

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
	ContentLength        int             `json:"c_len"`
	ContentType          string          `json:"c_type"`
	ContentSHA256        string          `json:"c_sha256"`
	InheritedPermissions json.RawMessage `json:"inherited_permissions,omitempty"`
	Grants               json.RawMessage `json:"grants"`
	Links                json.RawMessage `json:"publinks"`
}

type ResourceFull struct {
	Resource  Resource   `json:"resource"`
	Ancestors []Ancestor `json:"ancestors"`
	Children  []Resource `json:"children"`
}

type User struct {
	Email       string `json:"email"`
	DisplayName string `json:"display"`
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
