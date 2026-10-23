package core

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"path"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
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

func (f *FileSystem) PartialUploadWrite(user int32, uploadID uuid.UUID, src io.Reader, offset int64, checksum string) (int64, int64, error) {
	owner, size, uploaded, _, finalized, err := queryPartialUpload(f.db, uploadID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrUploadNotFound
		}
		return 0, 0, err
	}
	if user != owner {
		return 0, 0, ErrUploadNotFound
	}
	if finalized.Valid {
		return 0, 0, ErrUploadFinalized
	}

	path := uploadFilePath(user, uploadID)
	if stat, err := os.Stat(path); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			uploaded = 0
		} else {
			return 0, 0, err
		}
	} else {
		if stat.Size() < uploaded {
			uploaded = stat.Size()
		}
	}
	if offset > uploaded || offset < 0 {
		return 0, 0, NewError(http.StatusBadRequest, "upload_offset_exceeded", fmt.Sprintf("Upload Offset Exceeded. Requested %d of %d", offset, uploaded))
	}
	uploadFile, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0o600)
	if err != nil {
		return 0, 0, err
	}
	defer uploadFile.Close()
	if _, err := uploadFile.Seek(int64(offset), 0); err != nil {
		return 0, 0, err
	}

	hash := sha256.New()
	src = io.LimitReader(src, size-uploaded)
	src = io.TeeReader(src, hash)
	if written, err := io.Copy(uploadFile, src); err != nil {
		return 0, 0, err
	} else {
		if checksum != "" && checksum != hex.EncodeToString(hash.Sum(nil)) {
			return 0, 0, ErrUploadChecksumMismatch
		}
		// TODO: Return error if there is more data available in the reader
		offset += written
		return size, offset, updatePartialUploadUploaded(f.db, uploadID, offset)
	}

}

func (f *FileSystem) PartialUploadQuery(user int32, id uuid.UUID) (size, uploaded int64, err error) {
	var owner int32
	var finalized pgtype.UUID
	owner, size, uploaded, _, finalized, err = queryPartialUpload(f.db, id)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrUploadNotFound
		}
		return 0, 0, err
	}
	if user != owner {
		return 0, 0, ErrUploadNotFound
	}
	if finalized.Valid {
		return 0, 0, ErrUploadFinalized
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

func (f *FileSystem) PartialUploadFinalize(
	user int32,
	uploadID, resourceID, versionID uuid.UUID,
	resourcePath string,
	conflict ResourceBindConflictResolution,
) (uuid.UUID, error) {
	owner, size, uploaded, checksum, finalized, err := queryPartialUpload(f.db, uploadID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return uuid.Nil, ErrUploadNotFound
		}
		return uuid.Nil, err
	}
	if user != owner {
		return uuid.Nil, ErrUploadNotFound
	}

	if finalized.Valid {
		return finalized.Bytes, nil
	}

	uploadFilePath := uploadFilePath(user, uploadID)
	if stat, err := os.Stat(uploadFilePath); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			uploaded = 0
		} else {
			return uuid.Nil, err
		}
	} else {
		if stat.Size() < uploaded {
			uploaded = stat.Size()
		}
	}
	if size != uploaded {
		return uuid.Nil, ErrUploadIncomplete
	}
	uploadFile, err := os.Open(uploadFilePath)
	if err != nil {
		return uuid.Nil, err
	}
	defer uploadFile.Close()
	if checksum != "" {
		if sha256, err := computeSha256(uploadFile); err != nil {
			return uuid.Nil, err
		} else if sha256 != checksum {
			return uuid.Nil, ErrUploadChecksumMismatch
		}
		uploadFile.Seek(0, io.SeekStart)
	}

	if resourceID, err = f.CreateFileByPath(resourcePath, resourceID, versionID, uploadFile, conflict); err != nil {
		return uuid.Nil, err
	} else {
		os.Remove(uploadFilePath)
		updatePartialUploadFinalized(f.db, uploadID, resourceID)
	}
	return resourceID, nil
}

func insertPartialUpload(db db.TxHandler, id uuid.UUID, owner int32, size int64, checksum string) error {
	const q = `WITH ins AS (
	INSERT INTO partial_uploads(id, owner, size, uploaded, checksum)
	VALUES (@id, @owner, @size, 0, @checksum)
    ON CONFLICT (id) DO NOTHING
    RETURNING owner, size, checksum
)
SELECT owner, size, checksum FROM ins
UNION ALL
SELECT owner, size, checksum FROM partial_uploads
WHERE id = @id
AND NOT EXISTS (SELECT 1 FROM ins)`

	args := pgx.NamedArgs{
		"id":       id,
		"owner":    owner,
		"size":     size,
		"checksum": checksum,
	}
	row := db.QueryRow(q, args)
	var rowOwner int32
	var rowSize int64
	var rowChecksum pgtype.Text
	if err := row.Scan(&rowOwner, &rowSize, &rowChecksum); err != nil {
		return err
	}
	if owner != rowOwner || size != rowSize || checksum != rowChecksum.String {
		return ErrIDConflict
	}

	return nil
}

func queryPartialUpload(db db.Handler, id uuid.UUID) (owner int32, size, uploaded int64, checksum string, finalized pgtype.UUID, err error) {
	const q = `SELECT owner, size, uploaded, checksum, finalized_resource_id FROM partial_uploads WHERE id = @id`

	args := pgx.NamedArgs{
		"id": id,
	}
	row := db.QueryRow(q, args)
	err = row.Scan(&owner, &size, &uploaded, &checksum, &finalized)
	return
}

func updatePartialUploadUploaded(db db.Handler, id uuid.UUID, uploaded int64) error {
	const q = `UPDATE partial_uploads SET uploaded = @uploaded WHERE id = @id`

	args := pgx.NamedArgs{
		"id":       id,
		"uploaded": uploaded,
	}
	_, err := db.Exec(q, args)
	return err
}

func updatePartialUploadFinalized(db db.Handler, uploadID, resourceID uuid.UUID) error {
	const q = `UPDATE partial_uploads SET finalized_resource_id = @resource_id WHERE id = @upload_id`

	args := pgx.NamedArgs{
		"upload_id":   uploadID,
		"resource_id": resourceID,
	}
	_, err := db.Exec(q, args)
	return err
}

func uploadFilePath(userID int32, id uuid.UUID) string {
	return path.Join(os.TempDir(), fmt.Sprintf("%d-%s", userID, id.String()))
}
