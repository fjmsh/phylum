package steve

import (
	"encoding/json"
	"errors"
	"strconv"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/db"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgtype"
)

var errNoJobs = errors.New("no jobs in queue")
var ErrJobNotFound = errors.New("job not found")

type ErrJobBlocked struct {
	dependencies []JobInfo
}

func (e *ErrJobBlocked) Error() string {
	ids := make([]string, len(e.dependencies))
	for i, d := range e.dependencies {
		ids[i] = strconv.Itoa(int(d.ID))
	}
	return "job blocked by " + strings.Join(ids, ",")
}

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
	attempts = attempts+1,
	errors = errors || $2::JSONB, 
	status = $3::SMALLINT,
	scheduled_at = $4::TIMESTAMPTZ
WHERE id = $1::INT`
	if errJson, err := json.Marshal(attemptError); err != nil {
		return err
	} else {
		status := JobStatusErrorRetry
		if !scheduleAt.Valid {
			status = JobStatusFailed
		}
		_, err := db.Exec(q, jobID, errJson, status, scheduleAt)
		return err
	}
}

func resetRunningJobs(db db.Handler) error {
	const qResetStatus = "UPDATE jobs SET status = 2 WHERE status = 3"
	_, err := db.Exec(qResetStatus)
	return err
}

func readyScheduledJobs(db db.Handler) (int, error) {
	const q = "UPDATE jobs SET status = 2 WHERE status = 5 AND scheduled_at < NOW()"
	if tag, err := db.Exec(q); err != nil {
		return 0, err
	} else {
		return int(tag.RowsAffected()), err
	}
}

func readyBlockedJobs(db db.Handler) (int, error) {
	const q = `-- unblockJobs
WITH cte (id, count) AS (
	SELECT id, count(dependency) FROM jobs
	LEFT JOIN job_dependencies
	ON id = job_id
	WHERE status = 1
	GROUP BY id
) UPDATE jobs SET
	status = 2
WHERE id IN (SELECT id FROM cte WHERE count = 0)`
	if tag, err := db.Exec(q); err != nil {
		return 0, err
	} else {
		return int(tag.RowsAffected()), err
	}
}

func claimNextJob(db db.Handler, includeReady bool) (*JobInfo, error) {
	q := `-- ClaimNextJob
WITH cte (id, status) AS (
	SELECT id, status FROM jobs
	WHERE status = 0`
	if includeReady {
		q += " OR status = 2"
	}
	q += ` ORDER BY id
	FOR UPDATE SKIP LOCKED
	LIMIT 1
) UPDATE jobs SET
	status = 3
FROM cte
	WHERE jobs.id = (SELECT id FROM cte)
	RETURNING jobs.id, cte.status, jobs.attempts, jobs.kind, jobs.args`

	if rows, err := db.Query(q); err != nil {
		return nil, err
	} else {
		if info, err := pgx.CollectExactlyOneRow(rows, scanJobInfo); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				err = errNoJobs
			}
			return nil, err
		} else {
			return &info, nil
		}
	}
}

func insertDependencies(db db.Handler, jobID int32, sequences []string) (int, error) {
	const q = `-- InsertDependencies
INSERT INTO job_dependencies(job_id, dependency)
	(SELECT $1::INTEGER, job_id from job_sequences WHERE sequence = ANY ($2::TEXT[]))`
	if tag, err := db.Exec(q, jobID, sequences); err != nil {
		return 0, err
	} else {
		return int(tag.RowsAffected()), err
	}
}

func insertSequences(db db.Handler, jobID int32, sequences []string) (int, error) {
	const q = `-- InsertSequences
INSERT INTO job_sequences(job_id, sequence)
	(SELECT $1::INTEGER, unnest($2::TEXT[]))`

	if tag, err := db.Exec(q, jobID, sequences); err != nil {
		return 0, err
	} else {
		return int(tag.RowsAffected()), err
	}
}

func deleteDependencies(db db.Handler, jobID int32) error {
	const q = `DELETE FROM job_dependencies WHERE dependency = $1::INTEGER`
	_, err := db.Exec(q, jobID)
	return err
}

func deleteSequences(db db.Handler, jobID int32) error {
	const q = ` DELETE FROM job_sequences WHERE job_id = $1::INTEGER`
	_, err := db.Exec(q, jobID)
	return err
}

func ListJobs(db db.Handler, only, exclude []JobStatus) ([]JobInfo, error) {
	qb := strings.Builder{}
	qb.WriteString("SELECT id, status, attempts, kind, args FROM jobs")
	if len(only) > 0 {
		qb.WriteString(" WHERE status = ANY (@only::SMALLINT[])")
	} else if len(exclude) > 0 {
		qb.WriteString(" WHERE status <> ANY (@exclude::SMALLINT[])")
	}
	qb.WriteString(" ORDER BY id")

	args := pgx.NamedArgs{
		"only":    only,
		"exclude": exclude,
	}
	if rows, err := db.Query(qb.String(), args); err != nil {
		return nil, err
	} else {
		return pgx.CollectRows(rows, scanJobInfo)
	}
}

func GetJobDetails(db db.Handler, id int32) (JobDetails, error) {
	const q = `SELECT id, status, attempts, created_at, scheduled_at, kind, args, errors,
	(SELECT COALESCE(JSONB_AGG(ROW_TO_JSON(row)), '[]'::JSONB)
		FROM (SELECT j.id, j.status, j.attempts, j.kind, j.args FROM jobs j JOIN job_dependencies d ON j.id = d.job_id WHERE d.dependency = $1::INTEGER) row) AS dependents,
	(SELECT COALESCE(JSONB_AGG(ROW_TO_JSON(row)), '[]'::JSONB)
		FROM (SELECT j.id, j.status, j.attempts, j.kind, j.args FROM jobs j JOIN job_dependencies d ON j.id = d.dependency WHERE d.job_id = $1::INTEGER) row) AS dependencies
	FROM jobs WHERE id = $1::INTEGER`

	if rows, err := db.Query(q, id); err != nil {
		return JobDetails{}, err
	} else if job, err := pgx.CollectExactlyOneRow(rows, scanJobRow); err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			err = ErrJobNotFound
		}
		return JobDetails{}, err
	} else {
		return job, nil
	}
}

func scanJobInfo(row pgx.CollectableRow) (JobInfo, error) {
	var job JobInfo
	err := row.Scan(
		&job.ID,
		&job.Status,
		&job.Attempts,
		&job.Kind,
		&job.EncodedArgs,
	)
	return job, err
}
func scanJobRow(row pgx.CollectableRow) (JobDetails, error) {
	var job JobDetails
	var dependents []byte
	var dependencies []byte
	err := row.Scan(
		&job.ID,
		&job.Status,
		&job.Attempts,
		&job.CreatedAt,
		&job.ScheduledAt,
		&job.Kind,
		&job.EncodedArgs,
		&job.Errors,
		&dependents,
		&dependencies,
	)
	json.Unmarshal(dependents, &job.Dependents)
	json.Unmarshal(dependencies, &job.Dependencies)
	if err != nil {
		return JobDetails{}, err
	}

	return job, nil
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
