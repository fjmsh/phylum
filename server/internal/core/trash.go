package core

import (
	"context"
	"encoding/base64"
	"encoding/binary"
	"fmt"
	"time"

	"codeberg.org/shroff/phylum/server/internal/db"
	"codeberg.org/shroff/phylum/server/internal/jobs"
	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
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
	logrus.Info(fmt.Sprintf("Removing files deleted before %s", t.Format(time.RFC1123)))
	if err := hardDeleteOldResources(ctx, t); err != nil {
		logrus.Error(err)
	}
}

func (f filesystem) TrashSummary() (int, int, error) {
	v := goqu.T("resource_versions").As("v")

	r, q := f.selectTrash()
	q = q.LeftJoin(v, goqu.On(v.Col("resource_id").Eq(r.Col("id")))).
		Select(
			goqu.COALESCE(goqu.SUM(v.Col("size")), 0),
			goqu.COUNT(goqu.L("DISTINCT(?)", r.Col("id"))))

	query, args, _ := q.ToSQL()
	row := f.db.QueryRow(query, args...)
	var size int
	var items int
	err := row.Scan(&size, &items)
	return items, size, err
}

func (f filesystem) TrashEmpty() error {
	r, q := f.selectTrash()
	return hardDeleteAllVersions(f.db, q, r)
}

func (f filesystem) selectTrash() (exp.IdentifierExpression, *goqu.SelectDataset) {
	r := goqu.T("resources")
	t := goqu.T("trash").As("t")

	q := pg.
		From(r).
		Join(t, goqu.On(r.Col("id").Eq(t.Col("id"))))

	if !f.fullAccess {
		q = q.Where(goqu.L("r.permissions[?]::INTEGER <> 0", f.userID))
	}
	return r, q
}

func hardDeleteOldResources(ctx context.Context, t time.Time) error {
	r := goqu.T("resources")
	q := pg.From(r).Where(r.Col("deleted").Lt(goqu.V(t.UTC())))
	return hardDeleteAllVersions(db.Get(ctx), q, r)
}

func hardDeleteAllVersions(db db.Handler, q *goqu.SelectDataset, r exp.IdentifierExpression) error {
	v := goqu.T("resource_versions").As("v")
	query, params, _ := q.
		Join(v, goqu.On(r.Col("id").Eq(v.Col("resource_id")))).
		Where(v.Col("deleted").IsNotNull()).
		Select(v.Col("id"), v.Col("storage")).
		ToSQL()

	var versions []jobs.DeleteContentsArgs
	if rows, err := db.Query(query, params...); err != nil {
		return err
	} else if versions, err = collectDeletedVersions(rows); err != nil {
		return err
	}

	query, args, _ := q.Delete().ToSQL()

	if _, err := db.Exec(query, args...); err != nil {
		return err
	} else {
		jobs.DeleteContents(versions)
	}
	return nil
}

func collectNonDirResourceIDs(rows pgx.Rows, e error) (total int, ids []uuid.UUID, err error) {
	if e != nil {
		return 0, nil, e
	}
	defer rows.Close()
	var id uuid.UUID
	var dir bool
	for rows.Next() {
		if err := rows.Scan(&id, &dir); err != nil {
			return total, nil, err
		}
		if !dir {
			ids = append(ids, id)
		}
		total++
	}
	err = rows.Err()
	return total, ids, err
}
