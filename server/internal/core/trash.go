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

func (f fileSystem) TrashList(cursor string, n uint) ([]Resource, string, error) {
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
			pg.Select(goqu.L("CASE WHEN COALESCE(p.permissions[?::INT]::INTEGER, 0) <> 0 THEN p.id ELSE NULL END AS visible_parent", f.user.ID)),
			pg.Select(goqu.L("COALESCE(p.permissions, '{}'::JSONB)")),
		)
	if f.user.Permissions&PermissionFilesAll == 0 {
		q = q.Where(goqu.L("r.permissions[?::INT]::INTEGER <> 0", f.user.ID))
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
	} else if res, err := pgx.CollectRows(rows, scanFullResource); err != nil {
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
	f := openOmniscient(db.Get(ctx))
	if err := f.hardDeleteOldResources(t); err != nil {
		logrus.Error(err)
	}
}

func (f fileSystem) TrashSummary() (int, int, error) {
	v := goqu.T("resource_versions").As("v")

	n, q := f.selectTrash(time.Time{})
	q = q.LeftJoin(v, goqu.On(v.Col("resource_id").Eq(n.Col("id")))).
		Select(
			goqu.COALESCE(goqu.SUM(v.Col("size")), 0),
			goqu.COUNT(goqu.L("DISTINCT(?)", n.Col("id"))))

	query, args, _ := q.ToSQL()
	row := f.db.QueryRow(query, args...)
	var size int
	var items int
	err := row.Scan(&size, &items)
	return items, size, err
}

func (f fileSystem) TrashEmpty() error {
	n, q := f.selectTrash(time.Time{})
	return f.db.RunInTx(func(db db.TxHandler) error {
		return hardDeleteAllVersions(db, q, n)
	})
}

func (f fileSystem) selectTrash(time time.Time) (exp.AliasedExpression, *goqu.SelectDataset) {
	r := goqu.T("resources").As("r")
	n := goqu.T("nodes").As("n")
	t := goqu.T("trash").As("t")

	base := pg.
		From(r).
		Select(r.Col("id"), r.Col("parent"), r.Col("deleted")).
		Join(t, goqu.On(t.Col("id").Eq(r.Col("id"))))
	if f.user.Permissions&PermissionFilesAll == 0 {
		base = base.Where(goqu.L("r.permissions[?]::INTEGER <> 0", f.user.ID))
	}
	if !time.IsZero() {
		base = base.Where(r.Col("deleted").Lt(goqu.V(time.UTC())))
	}

	rec := pg.
		From(r).
		Select(r.Col("id"), r.Col("parent"), r.Col("deleted")).
		Join(n, goqu.On(r.Col("parent").Eq(n.Col("id")))).
		// Some children may be independently trashed (at different times). Don't select those
		Where(goqu.L("? IS NOT DISTINCT FROM ?", r.Col("deleted"), n.Col("deleted")))

	q := pg.From(n).WithRecursive("nodes(id, parent, deleted)", base.UnionAll(rec))

	return n, q
}

func (f fileSystem) hardDeleteOldResources(t time.Time) error {
	n, q := f.selectTrash(t)
	return f.db.RunInTx(func(db db.TxHandler) error {
		return hardDeleteAllVersions(db, q, n)
	})
}

func hardDeleteAllVersions(db db.TxHandler, q *goqu.SelectDataset, n interface {
	exp.Expression
	Col(interface{}) exp.IdentifierExpression
}) error {
	v := goqu.T("resource_versions").As("v")
	query, params, _ := q.
		Join(v, goqu.On(n.Col("id").Eq(v.Col("resource_id")))).
		Where(v.Col("deleted").IsNotNull()).
		Select(v.Col("id"), v.Col("storage")).
		ToSQL()

	var versions []jobs.DeleteContentsArgs
	if rows, err := db.Query(query, params...); err != nil {
		return err
	} else if versions, err = collectDeletedVersions(rows); err != nil {
		return err
	}

	r := goqu.T("resources")
	fmt.Println("DELETE QUERY")
	query, args, _ := q.
		From(r).
		Where(r.Col("id").Eq(pg.From(n).Select("id"))).
		Delete().ToSQL()

	if _, err := db.Exec(query, args...); err != nil {
		return err
	} else {
		jobs.DeleteContents(versions)
	}
	return nil
}
