package fs

import (
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

func (f filesystem) TrashList(cursor string, n uint) ([]Resource, string, error) {
	t := goqu.T("trash")
	r := goqu.T("resources").As("r")
	p := goqu.T("resources").As("p")
	l := goqu.T("publinks").As("l")
	q := pg.From(t).
		Join(r, goqu.On(t.Col("id").Eq(r.Col("id")))).
		Join(p, goqu.On(r.Col("parent").Eq(p.Col("id")))).
		Select(
			r.All(),
			pg.Select(goqu.L(publinkFieldsQuery)).From(l).Where(l.Col("root").Eq(r.Col("id"))),
			// TODO: Always select p.id when fullAccess
			pg.Select(goqu.L("CASE WHEN COALESCE(p.permissions[?]::INTEGER, 0) <> 0 THEN p.id ELSE NULL END AS visible_parent", f.userID)),
			pg.Select(goqu.L("COALESCE(p.permissions, '{}'::JSONB)")),
		)
	if !f.fullAccess {
		q = q.Where(goqu.L("r.permissions[?]::INTEGER <> 0", f.userID))
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
		OrderAppend(r.Col("id").Desc()).
		Limit(n).
		ToSQL()

	if rows, err := f.db.Query(query, params...); err != nil {
		return nil, "", err
	} else if res, err := pgx.CollectRows(rows, f.scanFullResource); err != nil {
		return nil, "", err
	} else {
		cursor := ""
		if uint(len(res)) == n {
			last := res[len(res)-1]
			c := make([]byte, 24)

			b, _ := last.id.MarshalBinary()
			copy(c, b)

			binary.LittleEndian.PutUint64(c[16:], uint64(last.deleted.Time.UnixNano()))
			cursor = base64.StdEncoding.EncodeToString(c)
		}
		return res, cursor, nil
	}
}
