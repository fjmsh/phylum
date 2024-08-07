package core

import "github.com/google/uuid"

type User interface {
	ID() int32
	Username() string
	DisplayName() string
	Root() uuid.UUID
}

type user struct {
	id          int32
	username    string
	displayName string
	root        uuid.UUID
}

func (u user) ID() int32           { return u.id }
func (u user) Username() string    { return u.username }
func (u user) DisplayName() string { return u.displayName }
func (u user) Root() uuid.UUID     { return u.root }
