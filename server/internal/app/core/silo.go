package core

import (
	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/db"
)

type Silo interface {
	ID() uuid.UUID
	Name() string
	Owner() int32
	StorageName() string
}

type silo struct {
	db      *db.DbHandler
	name    string
	owner   int32
	root    uuid.UUID
	storage Storage
}

func NewSilo(db *db.DbHandler, name string, owner int32, root uuid.UUID, storage Storage) Silo {
	return &silo{
		db:      db,
		name:    name,
		owner:   owner,
		root:    root,
		storage: storage,
	}
}

func (s *silo) ID() uuid.UUID {
	return s.root
}

func (s *silo) Name() string {
	return s.name
}

func (s *silo) Owner() int32 {
	return s.owner
}

func (s *silo) StorageName() string {
	return s.storage.Name()
}
