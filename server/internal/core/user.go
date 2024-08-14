package core

import "github.com/google/uuid"

type User struct {
	ID          int32
	Email       string
	DisplayName string
	Root        uuid.UUID
	Home        uuid.UUID
}
