package core

import "github.com/google/uuid"

type User struct {
	Username    string
	DisplayName string
	Root        uuid.UUID
	Home        uuid.UUID
}
