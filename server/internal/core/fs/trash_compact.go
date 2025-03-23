package fs

import (
	"context"
	"fmt"
	"time"

	"github.com/doug-martin/goqu/v9"
	"github.com/shroff/phylum/server/internal/core/db"
	"github.com/shroff/phylum/server/internal/core/storage"
	"github.com/sirupsen/logrus"
)

func TrashCompact(duration time.Duration) {
	t := time.Now().Add(-duration)
	if d, err := hardDeleteOldResources(t); err != nil {
		logrus.Error(err)
	} else {
		logrus.Info(fmt.Sprintf("Removed %d files deleted before %s", d, t.Format(time.RFC1123)))
	}
}

func hardDeleteOldResources(t time.Time) (int, error) {
	q := pg.
		From("resources").
		Where(goqu.C("deleted").Lt(goqu.V(t.UTC()))).
		Delete().
		Returning("id", "dir")
	query, args, _ := q.ToSQL()
	count, ids, err := collectNonDirResourceIDs(db.Get().Query(context.Background(), query, args...))
	if err != nil {
		return 0, err
	}
	errors := storage.Get().DeleteAll(ids)
	for _, err := range errors {
		logrus.Warn(err)
	}
	return count, err
}
