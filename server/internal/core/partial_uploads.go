package core

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"hash"
	"io"
	"net/http"
	"os"
	"path"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (f *FileSystem) PartialUploadCreate(user int32, id uuid.UUID, size int64, checksum string) error {
	path := uploadFilePath(user, id)
	return f.db.RunInTx(func(db db.TxHandler) error {
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

func (f *FileSystem) PartialUploadOpenWrite(user int32, id uuid.UUID, offset int64, checksum string) (io.WriteCloser, error) {
	owner, size, uploaded, _, err := queryPartialUpload(f.db, id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrUploadNotFound
		}
		return nil, err
	}
	if user != owner {
		return nil, ErrUploadNotFound
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
	if offset > uploaded || offset < 0 {
		return nil, NewError(http.StatusBadRequest, "upload_offset_exceeded", fmt.Sprintf("Upload Offset Exceeded. Requested %d of %d", offset, uploaded))
	}
	file, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0o600)
	if _, err := file.Seek(int64(offset), 0); err != nil {
		return nil, err
	}
	c := &contentUploader{
		id:       id,
		db:       f.db,
		dest:     file,
		size:     size,
		offset:   offset,
		checksum: checksum,
		hash:     sha256.New(),
	}
	return c, nil
}

func (f *FileSystem) PartialUploadQuery(user int32, id uuid.UUID) (size, uploaded int64, err error) {
	var owner int32
	owner, size, uploaded, _, err = queryPartialUpload(f.db, id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrUploadNotFound
		}
		return
	}
	if user != owner {
		err = ErrUploadNotFound
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

func (f *FileSystem) PartialUploadOpenRead(user int32, id uuid.UUID) (io.ReadCloser, func(), error) {
	owner, size, uploaded, checksum, err := queryPartialUpload(f.db, id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil, ErrUploadNotFound
		}
		return nil, nil, err
	}
	if user != owner {
		return nil, nil, ErrUploadNotFound
	}

	path := uploadFilePath(user, id)
	if stat, err := os.Stat(path); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			uploaded = 0
		} else {
			return nil, nil, err
		}
	} else {
		if stat.Size() < uploaded {
			uploaded = stat.Size()
		}
	}
	if size != uploaded {
		return nil, nil, ErrUploadIncomplete
	}
	file, err := os.Open(path)
	if checksum != "" {
		if sha256, err := computeSha256(file); err != nil {
			file.Close()
			return nil, nil, err
		} else if sha256 != checksum {
			file.Close()
			return nil, nil, ErrUploadChecksumMismatch
		}
		file.Seek(0, io.SeekStart)
	}
	cleanup := func() {
		// TODO: Log warnings?
		os.Remove(path)
		deletePartialUpload(f.db, id)
	}

	return file, cleanup, nil
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

func updatePartialUpload(db db.Handler, id uuid.UUID, uploaded int64) error {
	const q = `UPDATE partial_uploads SET uploaded = @uploaded WHERE id = @id`

	args := pgx.NamedArgs{
		"id":       id,
		"uploaded": uploaded,
	}
	_, err := db.Exec(q, args)
	return err
}
func deletePartialUpload(db db.Handler, id uuid.UUID) error {
	const q = `DELETE FROM partial_uploads WHERE id = @id`

	args := pgx.NamedArgs{
		"id": id,
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
	size     int64
	offset   int64
	n        int64
	checksum string
	hash     hash.Hash
}

func (c *contentUploader) Write(p []byte) (n int, err error) {
	if c.offset+c.n+int64(len(p)) > c.size {
		return 0, ErrUploadLengthExceeded
	}
	if c.checksum != "" {
		if _, err := c.hash.Write(p); err != nil {
			return 0, err
		}
	}
	n, err = c.dest.Write(p)
	c.n += int64(n)
	return
}

func (c *contentUploader) Close() error {
	if err := c.dest.Close(); err != nil {
		return err
	}
	if c.checksum != "" && c.checksum != hex.EncodeToString(c.hash.Sum(nil)) {
		return ErrUploadChecksumMismatch
	}
	return updatePartialUpload(c.db, c.id, c.offset+c.n)
}
