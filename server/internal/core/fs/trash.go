package fs

import (
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/db"
)

func (f filesystem) ListDeleted(cursor string, n int) ([]Resource, string, error) {
	var username pgtype.Text
	if !f.fullAccess {
		username.String = f.username
		username.Valid = true
	}

	var lastTimestamp pgtype.Timestamp
	var lastID uuid.UUID
	if cursor != "" {
		if d, err := base64.StdEncoding.DecodeString(cursor); err != nil {
			return nil, "", err
		} else if len(d) != 24 {
			return nil, "", fmt.Errorf("illegal cursor. Length %d not expected", len(d))
		} else {
			lastID, _ = uuid.FromBytes(d[:16])
			t := int64(binary.LittleEndian.Uint64(d[16:]))
			lastTimestamp.Time = time.Unix(t/1e9, t%1e9).UTC()
			lastTimestamp.Valid = true
		}
	}

	if res, err := f.db.ListDeleted(f.ctx, db.ListDeletedParams{
		Username:      username,
		N:             int32(n),
		LastTimestamp: lastTimestamp,
		LastID:        lastID,
	}); err != nil {
		return nil, "", err
	} else {
		if res == nil {
			return nil, "", nil
		}
		deleted := make([]Resource, len(res))
		for i, r := range res {
			deleted[i] = ResourceFromDB(r)
		}
		last := deleted[len(deleted)-1]
		c := make([]byte, 24)

		b, _ := last.id.MarshalBinary()
		copy(c, b)

		binary.LittleEndian.PutUint64(c[16:], uint64(last.deleted.UnixNano()))
		return deleted, base64.StdEncoding.EncodeToString(c), nil
	}
}
