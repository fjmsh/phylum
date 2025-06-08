package core

import (
	"context"
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/shroff/phylum/server/internal/db"
	"github.com/sirupsen/logrus"
)

func (f filesystem) TrashList(cursor string, n uint) ([]Resource, string, error) {
	t := goqu.T("trash")
	r := goqu.T("resources").As("r")
	p := goqu.T("resources").As("p")
	v := goqu.T("resource_versions").As("v")
	l := goqu.T("publinks").As("l")
	q := pg.From(t).
		Join(r, goqu.On(t.Col("id").Eq(r.Col("id")))).
		Join(p, goqu.On(r.Col("parent").Eq(p.Col("id")))).
		Select(
			r.All(),
			pg.Select(goqu.L(versionsQuery)).From(v).Where(v.Col("resource_id").Eq(r.Col("id"))),
			pg.Select(goqu.L(publinksQuery)).From(l).Where(l.Col("root").Eq(r.Col("id"))),
			// TODO: Always select p.id when fullAccess
			pg.Select(goqu.L("CASE WHEN COALESCE(p.permissions[?::INT]::INTEGER, 0) <> 0 THEN p.id ELSE NULL END AS visible_parent", f.userID)),
			pg.Select(goqu.L("COALESCE(p.permissions, '{}'::JSONB)")),
		)
	if !f.fullAccess {
		q = q.Where(goqu.L("r.permissions[?::INT]::INTEGER <> 0", f.userID))
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

func TrashCompact(ctx context.Context, duration time.Duration) {
	t := time.Now().Add(-duration)
	if d, err := hardDeleteOldResources(ctx, t); err != nil {
		logrus.Error(err)
	} else {
		logrus.Info(fmt.Sprintf("Removed %d files deleted before %s", d, t.Format(time.RFC1123)))
	}
}

func (f filesystem) TrashSummary() (int, int, error) {
	q := f.selectDeletedResources().
		Select(
			goqu.COALESCE(goqu.SUM("content_length"), 0),
			goqu.COUNT("*"))

	query, args, _ := q.ToSQL()
	row := f.db.QueryRow(query, args...)
	var size int
	var items int
	err := row.Scan(&size, &items)
	return items, size, err
}

func (f filesystem) TrashEmpty() (int, error) {
	q := f.selectDeletedResources().
		Delete().
		Returning("id", "dir")
	query, args, _ := q.ToSQL()
	count, ids, err := collectNonDirResourceIDs(f.db.Query(query, args...))
	deleteAllVersionContents(f.db, ids)
	return count, err
}

func (f filesystem) selectDeletedResources() *goqu.SelectDataset {
	q := pg.
		From("resources").
		Where(goqu.C("deleted").IsNotNull())
	if !f.fullAccess {
		q = q.Where(goqu.L("permissions[?]::INTEGER <> 0", f.userID))
	}
	return q
}

func hardDeleteOldResources(ctx context.Context, t time.Time) (int, error) {
	q := pg.
		From("resources").
		Where(goqu.C("deleted").Lt(goqu.V(t.UTC()))).
		Delete().
		Returning("id", "dir")
	query, args, _ := q.ToSQL()
	db := db.Get(ctx)
	count, ids, err := collectNonDirResourceIDs(db.Query(query, args...))
	if err != nil {
		return 0, err
	}
	deleteAllVersionContents(db, ids)
	return count, err
}
