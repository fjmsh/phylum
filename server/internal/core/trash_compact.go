package core

import (
	"context"
	"fmt"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/sirupsen/logrus"
)

func TrashCompact(ctx context.Context, duration time.Duration) {
	t := time.Now().Add(-duration)
	if d, err := hardDeleteOldResources(ctx, t); err != nil {
		logrus.Error(err)
	} else {
		logrus.Info(fmt.Sprintf("Removed %d files deleted before %s", d, t.Format(time.RFC1123)))
	}
}

func hardDeleteOldResources(ctx context.Context, t time.Time) (int, error) {
	q := pg.
		From("resources").
		Where(goqu.C("deleted").Lt(goqu.V(t.UTC()))).
		Delete().
		Returning("id", "dir")
	query, args, _ := q.ToSQL()
	count, ids, err := collectNonDirResourceIDs(db.Get(ctx).Query(query, args...))
	if err != nil {
		return 0, err
	}
	deleteResourcesContents(ids)
	return count, err
}
