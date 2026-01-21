package core

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"hash"
	"io"
	"os"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (f *FileSystem) CreatePartialUpload(owner int32, size int64, sha256 string) (uuid.UUID, error) {
	id, _ := uuid.NewV7()

	path := "path"
	return id, f.db.RunInTx(func(db db.TxHandler) error {
		if err := insertPartialUpload(db, id, owner, size, sha256); err != nil {
			return err
		}
		if file, err := os.Create(path); err != nil {
			return err
		} else {
			return file.Close()
		}
	})
}

func (f *FileSystem) OpenPartialUpload(id uuid.UUID, offset int64, user int32) (io.WriteCloser, error) {
	owner, size, uploaded, chunkSHA256, err := queryPartialUpload(f.db, id)
	if err != nil {
		return nil, err
	}
	if user != owner {
		return nil, ErrInsufficientPermissions
	}

	path := "path"
	if stat, err := os.Stat(path); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			uploaded = 0
		} else {
			return nil, err
		}
	} else {
		if stat.Size() < uploaded {
			uploaded = stat.Size()
		}
	}
	if offset > uploaded {
		return nil, ErrContentOffsetExceeded
	}
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0o600)
	if _, err := file.Seek(int64(offset), 0); err != nil {
		return nil, err
	}
	c := &contentUploader{
		id:       id,
		db:       f.db,
		dest:     file,
		maxBytes: int(size - uploaded),
		checksum: chunkSHA256,
		hash:     sha256.New(),
	}
	return c, nil
}

func insertPartialUpload(db db.TxHandler, id uuid.UUID, owner int32, size int64, sha256 string) error {
	const q = `INSERT INTO partial_uploads(id, owner, size, @uploaded, sha256)
	VALUES (@id, @owner, @size, 0, @sha256)`

	args := pgx.NamedArgs{
		"id":     id,
		"owner":  owner,
		"size":   size,
		"sha256": sha256,
	}
	_, err := db.Exec(q, args)
	if err != nil && strings.Contains(err.Error(), "partial_uploads_pkey") {
		return ErrIDConflict
	}
	return err
}

func queryPartialUpload(db db.Handler, id uuid.UUID) (owner int32, size, uploaded int64, sha256 string, err error) {
	const q = `SELECT (owner, size, uploaded, sha256) FROM partial_uploads WHERE id = @id`

	args := pgx.NamedArgs{
		"id": id,
	}
	row := db.QueryRow(q, args)
	err = row.Scan(owner, size, uploaded, sha256)
	return
}

func updatePartialUpload(db db.Handler, id uuid.UUID, written int) error {
	const q = `UPDATE partial_uploads SET uploaded = uploaded + @written WHERE id = @id`

	args := pgx.NamedArgs{
		"id":      id,
		"written": written,
	}
	_, err := db.Exec(q, args)
	return err
}

type contentUploader struct {
	id       uuid.UUID
	db       db.Handler
	dest     io.WriteCloser
	maxBytes int
	n        int
	checksum string
	hash     hash.Hash
}

func (c *contentUploader) Write(p []byte) (n int, err error) {
	if len(p) > c.maxBytes {
		return 0, ErrContentLengthExceeded
	}
	if c.checksum != "" {
		if _, err := c.hash.Write(p); err != nil {
			return 0, err
		}
	}
	n, err = c.dest.Write(p)
	c.n += n
	return
}

func (c *contentUploader) Close() error {
	if err := c.dest.Close(); err != nil {
		return err
	}
	if c.checksum != "" && c.checksum != hex.EncodeToString(c.hash.Sum(nil)) {
		return ErrContentChecksumMismatch
	}
	return updatePartialUpload(c.db, c.id, c.n)
}
