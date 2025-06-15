package steve

import (
	"context"
	"encoding/json"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgtype"
)

type db interface {
	BeginFunc(context.Context, func(pgx.Tx) error) error
	Exec(context.Context, string, ...interface{}) (pgconn.CommandTag, error)
	Query(context.Context, string, ...interface{}) (pgx.Rows, error)
	QueryRow(context.Context, string, ...interface{}) (pgx.Row, error)
}

var errNoJobs = errors.New("no jobs in queue")

// For bulk insert
type insertJobParams struct {
	Kind        string
	EncodedArgs []byte
}

func insertJobs(ctx context.Context, tx pgx.Tx, arg []insertJobParams) (int64, error) {
	return tx.CopyFrom(ctx, []string{"jobs"}, []string{"kind", "args"}, &iteratorForInsertJobParams{rows: arg})
}

func updateJobStatus(ctx context.Context, tx pgx.Tx, jobID int32, status JobStatus) error {
	const q = `UPDATE jobs SET status = $2::SMALLINT WHERE id = $1::INT`
	_, err := tx.Exec(ctx, q, jobID, status)
	return err
}

func updateJobStatusError(ctx context.Context, tx pgx.Tx, jobID int32, attemptError AttemptError, scheduleAt pgtype.Timestamptz) error {
	const q = `-- updateJobStatusError
UPDATE jobs SET
	attempts = attempts+1,
	errors = errors || $2::JSONB, 
	status = $3::SMALLINT,
	retry_at = $4::TIMESTAMPTZ
WHERE id = $1::INT`
	if errJson, err := json.Marshal(attemptError); err != nil {
		return err
	} else {
		status := JobStatusScheduled
		if !scheduleAt.Valid {
			status = JobStatusFailed
		}
		_, err := tx.Exec(ctx, q, jobID, errJson, status, scheduleAt)
		return err
	}
}

func resetRunningJobs(ctx context.Context, db db) error {
	const q = "UPDATE jobs SET status = 0 WHERE status = 1"
	_, err := db.Exec(ctx, q)
	return err
}

func enqueueScheduledJobs(ctx context.Context, db db) (int, error) {
	const q = "UPDATE jobs SET status = 0 WHERE status = 3 AND scheduled_at < NOW() RETURNING COUNT(*)"
	row, err := db.QueryRow(ctx, q)
	if err != nil {
		return 0, err
	}
	var count int
	err = row.Scan(&count)
	return count, err
}

func claimNextJob(ctx context.Context, db db) (*JobInfo, error) {
	const q = `-- ClaimNextJob
WITH cte (id) AS (
	SELECT id FROM jobs
	WHERE status = 0
	ORDER BY id
	FOR UPDATE SKIP LOCKED
	LIMIT 1
) UPDATE jobs SET
	status = 1,
	attempted_at = now()
WHERE id = (SELECT id FROM cte)
RETURNING id, status, attempt, kind, args`

	if rows, err := db.Query(ctx, q); err != nil {
		return nil, err
	} else {
		info, err := pgx.CollectExactlyOneRow(rows, scanJobInfo)
		if errors.Is(err, pgx.ErrNoRows) {
			err = errNoJobs
		}
		return info, err
	}
}
func scanJobInfo(row pgx.CollectableRow) (*JobInfo, error) {
	var job JobInfo
	err := row.Scan(
		&job.ID,
		&job.Status,
		&job.Attempt,
		&job.Kind,
		&job.EncodedArgs,
	)
	if err == nil {
		return nil, err
	}

	return &job, nil
}

// iteratorForInsertResourceVersionsFast implements pgx.CopyFromSource.
type iteratorForInsertJobParams struct {
	rows                 []insertJobParams
	skippedFirstNextCall bool
}

func (r *iteratorForInsertJobParams) Next() bool {
	if len(r.rows) == 0 {
		return false
	}
	if !r.skippedFirstNextCall {
		r.skippedFirstNextCall = true
		return true
	}
	r.rows = r.rows[1:]
	return len(r.rows) > 0
}

func (r iteratorForInsertJobParams) Values() ([]interface{}, error) {
	return []interface{}{
		r.rows[0].Kind,
		r.rows[0].EncodedArgs,
	}, nil
}

func (r iteratorForInsertJobParams) Err() error {
	return nil
}
