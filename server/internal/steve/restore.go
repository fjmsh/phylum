package steve

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
)

type db interface {
	Exec(ctx context.Context, stmt string, args ...interface{}) (pgconn.CommandTag, error)
	Query(ctx context.Context, stmt string, args ...interface{}) (pgx.Rows, error)
}

func restoreJobQueue(ctx context.Context, db db, workers *Workers) ([]WorkUnit, error) {
	const restoreStatus = "UPDATE jobs SET state = 0 WHERE state = 1"
	if _, err := db.Exec(ctx, restoreStatus); err != nil {
		return nil, err
	}

	const q = `SELECT id, state, attempt, created_at, attampted_at, finalized_at, args, errors, kind FROM jobs
WHERE finalized_at IS NULL
ORDER BY id`

	if rows, err := db.Query(ctx, q); err != nil {
		return nil, err
	} else if jobRows, err := pgx.CollectRows(rows, scanJob); err != nil {
		return nil, err
	} else {
		work := make([]WorkUnit, len(jobRows))
		for i, r := range jobRows {
			if w, err := workers.pkg(&r); err != nil {
				return nil, err
			} else {
				work[i] = w
			}
		}
		return work, nil
	}
}

func scanJob(row pgx.CollectableRow) (JobRow, error) {
	var job JobRow
	err := row.Scan(
		&job.ID,
		&job.State,
		&job.Attempt,
		&job.CreatedAt,
		&job.AttemptedAt,
		&job.FinalizedAt,
		&job.EncodedArgs,
		&job.Errors,
		&job.Kind,
	)

	return job, err
}
