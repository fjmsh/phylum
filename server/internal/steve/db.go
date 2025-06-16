package steve

import (
	"encoding/json"
	"errors"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var errNoJobs = errors.New("no jobs in queue")

// For bulk insert
type insertJobParams struct {
	Kind        string
	EncodedArgs []byte
}

func insertJobs(db db.Handler, arg []insertJobParams) (int64, error) {
	return db.CopyFrom([]string{"jobs"}, []string{"kind", "args"}, &iteratorForInsertJobParams{rows: arg})
}

func updateJobStatus(db db.Handler, jobID int32, status JobStatus) error {
	const q = `UPDATE jobs SET status = $2::SMALLINT WHERE id = $1::INT`
	_, err := db.Exec(q, jobID, status)
	return err
}

func updateJobStatusError(db db.Handler, jobID int32, attemptError AttemptError, scheduleAt pgtype.Timestamptz) error {
	const q = `-- updateJobStatusError
UPDATE jobs SET
	attempt = attempt+1,
	errors = errors || $2::JSONB, 
	status = $3::SMALLINT,
	scheduled_at = $4::TIMESTAMPTZ
WHERE id = $1::INT`
	if errJson, err := json.Marshal(attemptError); err != nil {
		return err
	} else {
		status := JobStatusScheduled
		if !scheduleAt.Valid {
			status = JobStatusFailed
		}
		_, err := db.Exec(q, jobID, errJson, status, scheduleAt)
		return err
	}
}

func resetDB(db db.Handler) error {
	const qResetStatus = "UPDATE jobs SET status = 0 WHERE status = 1 OR status = 6"
	_, err := db.Exec(qResetStatus)
	return err
}

func enqueueScheduledJobs(db db.Handler) (int, error) {
	const q = "UPDATE jobs SET status = 0 WHERE status = 3 AND scheduled_at < NOW()"
	if tag, err := db.Exec(q); err != nil {
		return 0, err
	} else {
		return int(tag.RowsAffected()), err
	}
}

func claimNextJob(db db.Handler) (*JobInfo, error) {
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

	if rows, err := db.Query(q); err != nil {
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
	if err != nil {
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
