package core

import (
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/util/crypt"
)

type Publink struct {
	ID           string
	Created      time.Time
	Root         uuid.UUID
	Accessed     int32
	AccessLimit  int32
	PasswordHash string
	Expires      int64
}

type ROFileSystem interface {
	ResourceByPath(string) (Resource, error)
	ReadDir(Resource, bool) ([]Resource, error)
	FindVersion(Resource, uuid.UUID) (Version, error)
	Walk(Resource, int, func(Resource, string) error) error
}

type roFilesystem struct {
	f filesystem
}

func (f roFilesystem) ResourceByPath(path string) (Resource, error) {
	return f.f.ResourceByPath(path)
}
func (f roFilesystem) ReadDir(r Resource, recursive bool) ([]Resource, error) {
	return f.f.ReadDir(r, recursive)
}

func (f roFilesystem) FindVersion(r Resource, versionID uuid.UUID) (Version, error) {
	return f.f.FindVersion(r, versionID)
}

func (f roFilesystem) Walk(r Resource, depth int, fn func(Resource, string) error) error {
	return f.f.Walk(r, depth, fn)
}

func scanPublink(row pgx.CollectableRow) (Publink, error) {
	var p Publink
	var expires *time.Time
	if err := row.Scan(
		&p.ID,
		&p.Created,
		&p.Root,
		&p.Accessed,
		&p.AccessLimit,
		&p.PasswordHash,
		&expires,
	); err != nil {
		return Publink{}, err
	}
	if expires != nil {
		p.Expires = expires.UnixMilli()
	}
	return p, nil
}

func (f filesystem) CreatePublink(r Resource, id, password string, expires pgtype.Timestamp, accessLimit int) error {
	if !r.hasPermission(PermissionShare | PermissionRead) {
		return ErrInsufficientPermissions
	}
	if r.deleted.Valid {
		return ErrResourceDeleted
	}

	passwordHash := ""

	if password != "" {
		hash, err := crypt.Generate(password)
		if err != nil {
			return err
		}
		passwordHash = hash
	}

	const q = `INSERT INTO publinks(id, root, password_hash, expires, access_limit) VALUES
	($1::text, $2::uuid, $3::text, $4::timestamp, $5::int)`

	_, err := f.db.Exec(q, id, r.ID(), passwordHash, expires, accessLimit)
	if err != nil && strings.Contains(err.Error(), "publinks_pkey") {
		return ErrPublinkNameConflict
	}
	return err
}

func (f filesystem) ListPublinks(r Resource) ([]Publink, error) {
	const q = "SELECT * FROM publinks WHERE root = $1::UUID"
	if rows, err := f.db.Query(q, r.id); err != nil {
		return nil, err
	} else if links, err := pgx.CollectRows(rows, scanPublink); err != nil {
		return nil, err
	} else {
		return links, nil
	}
}
