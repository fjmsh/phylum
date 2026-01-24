package core

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"hash"
	"io"
	"os"
	"path"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (f *FileSystem) CreatePartialUpload(user int32, size int64, checksum string) (uuid.UUID, error) {
	id, _ := uuid.NewV7()

	path := uploadFilePath(user, id)
	return id, f.db.RunInTx(func(db db.TxHandler) error {
		if err := insertPartialUpload(db, id, user, size, checksum); err != nil {
			return err
		}
		if file, err := os.Create(path); err != nil {
			return err
		} else {
			return file.Close()
		}
	})
}

func (f *FileSystem) OpenPartialUpload(user int32, id uuid.UUID, offset int64) (io.WriteCloser, error) {
	owner, size, uploaded, checksum, err := queryPartialUpload(f.db, id)
	if err != nil {
		return nil, err
	}
	if user != owner {
		return nil, ErrResourceNotFound
	}

	path := uploadFilePath(user, id)
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
		return nil, ErrUploadOffsetExceeded
	}
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0o600)
	if _, err := file.Seek(int64(offset), 0); err != nil {
		return nil, err
	}
	c := &contentUploader{
		id:       id,
		db:       f.db,
		dest:     file,
		maxBytes: int(size - offset),
		checksum: checksum,
		hash:     sha256.New(),
	}
	return c, nil
}

func (f *FileSystem) QueryPartialUpload(user int32, id uuid.UUID) (size, uploaded int64, err error) {
	var owner int32
	owner, size, uploaded, _, err = queryPartialUpload(f.db, id)
	if err != nil {
		return
	}
	if user != owner {
		err = ErrResourceNotFound
		return
	}

	path := uploadFilePath(user, id)
	var stat os.FileInfo
	if stat, err = os.Stat(path); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			uploaded = 0
			err = nil
		} else {
			return
		}
	} else {
		if stat.Size() < uploaded {
			uploaded = stat.Size()
		}
	}
	return
}

func (f *FileSystem) ReadPartialUpload(user int32, id uuid.UUID) (io.ReadCloser, error) {
	owner, size, uploaded, _, err := queryPartialUpload(f.db, id)
	if err != nil {
		return nil, err
	}
	if user != owner {
		return nil, ErrResourceNotFound
	}

	path := uploadFilePath(user, id)
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
	if size != uploaded {
		return nil, ErrUploadIncomplete
	}
	file, err := os.Open(path)
	return file, nil
}

func insertPartialUpload(db db.TxHandler, id uuid.UUID, owner int32, size int64, checksum string) error {
	const q = `INSERT INTO partial_uploads(id, owner, size, uploaded, checksum)
	VALUES (@id, @owner, @size, 0, @checksum)`

	args := pgx.NamedArgs{
		"id":       id,
		"owner":    owner,
		"size":     size,
		"checksum": checksum,
	}
	_, err := db.Exec(q, args)
	if err != nil && strings.Contains(err.Error(), "partial_uploads_pkey") {
		return ErrIDConflict
	}
	return err
}

func queryPartialUpload(db db.Handler, id uuid.UUID) (owner int32, size, uploaded int64, checksum string, err error) {
	const q = `SELECT owner, size, uploaded, checksum FROM partial_uploads WHERE id = @id`

	args := pgx.NamedArgs{
		"id": id,
	}
	row := db.QueryRow(q, args)
	err = row.Scan(&owner, &size, &uploaded, &checksum)
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

func uploadFilePath(userID int32, id uuid.UUID) string {
	return path.Join(os.TempDir(), fmt.Sprintf("%d-%s", userID, id.String()))
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
		return 0, ErrUploadLengthExceeded
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
		return ErrUploadChecksumMismatch
	}
	return updatePartialUpload(c.db, c.id, c.n)
}
