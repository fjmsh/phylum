package core

import (
	"context"
	"errors"
	"time"

	"codeberg.org/shroff/phylum/server/internal/auth/crypt"
	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

type proxyFileSystemReadOnly struct {
	f *FileSystem
}

func (f proxyFileSystemReadOnly) ResourceByPath(path string) (Resource, error) {
	return f.f.ResourceByPath(path)
}
func (f proxyFileSystemReadOnly) ReadDir(r Resource, recursive bool) ([]Resource, error) {
	return f.f.ReadDir(r, recursive)
}

func (f proxyFileSystemReadOnly) GetVersion(r Resource, versionID uuid.UUID) (Version, error) {
	return f.f.GetVersion(r, versionID)
}

func (f proxyFileSystemReadOnly) Walk(r Resource, depth int, fn func(Resource, string) error) error {
	return f.f.Walk(r, depth, fn)
}

func OpenFileSystemFromPublink(ctx context.Context, id string, password string) (ReadFileSystem, error) {
	d := db.Get(ctx)
	link, err := getPublink(d, id)
	if err != nil {
		return nil, err
	}

	// check password
	if link.PasswordHash != "" {
		if password == "" {
			return nil, ErrInsufficientPermissions
		}
		if ok, err := crypt.Verify(password, link.PasswordHash); err != nil {
			return nil, err
		} else if !ok {
			return nil, ErrInsufficientPermissions
		}
	}

	// check expiration
	if link.Expires != 0 && time.UnixMilli(link.Expires).Before(time.Now()) {
		return nil, ErrResourceNotFound
	}

	// check max accesses
	if link.AccessLimit > 0 && link.AccessLimit <= link.Accessed {
		return nil, ErrResourceNotFound
	}

	const q = "UPDATE publinks SET accessed = accessed + 1 WHERE id = $1"
	if err := d.RunInTx(func(db db.TxHandler) error {
		_, err := db.Exec(q, link.ID)
		return err
	}); err != nil {
		return nil, err
	}

	// TODO: #redundant
	// TODO: #do not use omniscient
	return proxyFileSystemReadOnly{f: openOmniscient(d).withPathRoot(pgtype.UUID{Bytes: link.Root, Valid: true})}, nil
}

func getPublink(d db.Handler, id string) (Publink, error) {
	q := "SELECT * FROM publinks p WHERE id = $1::TEXT"
	if rows, err := d.Query(q, id); err != nil {
		return Publink{}, err
	} else if link, err := pgx.CollectExactlyOneRow(rows, scanPublink); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrParentNotFound
		}
		return Publink{}, err
	} else {
		return link, nil
	}
}
