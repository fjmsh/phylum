package fs

import (
	"github.com/doug-martin/goqu/v9"
	"github.com/doug-martin/goqu/v9/exp"
	"github.com/google/uuid"
)

func selectResourceTree(ds *goqu.SelectDataset, nodes exp.IdentifierExpression, id uuid.UUID, includeDeleted bool) *goqu.SelectDataset {
	resTable := goqu.T("resources").As("r")
	rec := pg.From(resTable).
		Select(resTable.Col("id"), resTable.Col("parent"), resTable.Col("deleted"), goqu.L("? + 1", goqu.I("n.depth"))).
		Join(nodes.As("n"), goqu.On(goqu.I("r.parent").Eq(goqu.I("n.id"))))

	if !includeDeleted {
		rec = rec.Where(
			goqu.Or(
				goqu.I("r.deleted").Eq(goqu.I("n.deleted")),
				goqu.And(
					goqu.I("r.deleted").IsNull(),
					goqu.I("n.deleted").IsNull(),
				)))
	}

	return ds.WithRecursive(nodes.GetTable()+"(id, parent, deleted, depth)",
		pg.From(resTable).
			Select(resTable.Col("id"), resTable.Col("parent"), resTable.Col("deleted"), goqu.L("0")).
			Where(goqu.I("r.id").Eq(id)).
			UnionAll(rec))
}
