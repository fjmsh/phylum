package user

import "github.com/google/uuid"

type User struct {
	Username    string    `json:"username"`
	DisplayName string    `json:"display"`
	Root        uuid.UUID `json:"root"`
	Home        uuid.UUID `json:"home"`
}
