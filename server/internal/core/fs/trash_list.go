package fs

import (
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

func (f filesystem) TrashList(cursor string, n uint) ([]Resource, string, error) {
	var username pgtype.Text
	if !f.fullAccess {
		username.String = f.username
		username.Valid = true
	}

	q := pg.From("resources").
		Where(goqu.C("deleted").IsNotNull())
	if !f.fullAccess {
		q = q.Where(goqu.L("permissions[?]::INTEGER <> 0", f.username))
	}
	if cursor != "" {
		if d, err := base64.StdEncoding.DecodeString(cursor); err != nil {
			return nil, "", err
		} else if len(d) != 24 {
			return nil, "", fmt.Errorf("illegal cursor. Length %d not expected", len(d))
		} else {
			t := int64(binary.LittleEndian.Uint64(d[16:]))
			lastID, _ := uuid.FromBytes(d[:16])
			lastTimestamp := time.Unix(t/1e9, t%1e9).UTC()
			q = q.Where(
				goqu.Or(
					goqu.I("deleted").Lt(goqu.V(lastTimestamp)),
					goqu.And(
						goqu.I("deleted").Eq(goqu.V(lastTimestamp)),
						goqu.I("id").Lt(goqu.V(lastID)),
					)))
		}
	}

	query, params, _ := q.
		Order(goqu.C("deleted").Desc()).
		OrderAppend(goqu.C("id").Desc()).
		Limit(n).
		ToSQL()

	if rows, err := f.db.Query(f.ctx, query, params...); err != nil {
		return nil, "", err
	} else if res, err := pgx.CollectRows(rows, f.readResource); err != nil {
		return nil, "", err
	} else {
		if res == nil {
			return nil, "", nil
		}
		last := res[len(res)-1]
		c := make([]byte, 24)

		b, _ := last.id.MarshalBinary()
		copy(c, b)

		binary.LittleEndian.PutUint64(c[16:], uint64(last.deleted.UnixNano()))
		return res, base64.StdEncoding.EncodeToString(c), nil
	}
}
