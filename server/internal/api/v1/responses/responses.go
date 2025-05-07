package responses

import (
	"encoding/json"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
)

type Ancestor struct {
	ID          uuid.UUID   `json:"id"`
	Name        string      `json:"name"`
	ParentID    pgtype.UUID `json:"parent"`
	Permissions string      `json:"permissions"`
}

type Resource struct {
	ID            uuid.UUID       `json:"id"`
	Name          string          `json:"name"`
	ParentID      pgtype.UUID     `json:"parent"`
	Dir           bool            `json:"dir"`
	Created       int64           `json:"created"`
	Modified      int64           `json:"modified"`
	Deleted       int64           `json:"deleted"`
	ContentLength int             `json:"c_len"`
	ContentType   string          `json:"c_type"`
	ContentSHA256 string          `json:"c_sha256"`
	Permissions   string          `json:"permissions"`
	Grants        string          `json:"grants"`
	Links         json.RawMessage `json:"publinks"`
}

type ResourceFull struct {
	Resource  Resource   `json:"resource"`
	Ancestors []Ancestor `json:"ancestors"`
	Children  []Resource `json:"children"`
}

type User struct {
	Username    string `json:"username"`
	DisplayName string `json:"display"`
}
