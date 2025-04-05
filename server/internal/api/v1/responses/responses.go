package responses

import (
	"time"

	"github.com/google/uuid"
)

type Ancestor struct {
	ID          uuid.UUID `json:"id"`
	Name        string    `json:"name"`
	ParentID    uuid.UUID `json:"parent"`
	Permissions string    `json:"permissions"`
}

type Resource struct {
	ID            uuid.UUID `json:"id"`
	Name          string    `json:"name"`
	ParentID      uuid.UUID `json:"parent"`
	Dir           bool      `json:"dir"`
	Created       time.Time `json:"created"`
	Modified      time.Time `json:"modified"`
	ContentLength int       `json:"c_len"`
	ContentType   string    `json:"c_type"`
	ContentSHA256 string    `json:"c_sha256"`
	Permissions   string    `json:"permissions"`
	Grants        string    `json:"grants"`
	Links         string    `json:"links"`
}

type ResourceFull struct {
	Resource  Resource   `json:"resource"`
	Ancestors []Ancestor `json:"ancestors"`
	Children  []Resource `json:"children"`
}
