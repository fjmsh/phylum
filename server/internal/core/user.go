package core

import "github.com/google/uuid"

type User interface {
	ID() int32
	Email() string
	DisplayName() string
	Root() uuid.UUID
	Home() uuid.UUID
}

type user struct {
	id          int32
	email       string
	displayName string
	root        uuid.UUID
	home        uuid.UUID
}

func (u user) ID() int32           { return u.id }
func (u user) Email() string       { return u.email }
func (u user) DisplayName() string { return u.displayName }
func (u user) Root() uuid.UUID     { return u.root }
func (u user) Home() uuid.UUID     { return u.home }
