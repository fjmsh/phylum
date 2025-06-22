package steve

import (
	"strconv"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

type Job[T JobArgs] struct {
	*JobInfo
	Args T
}

type JobArgs interface {
	Kind() string
	Sequences() []string
}

type JobInfo struct {
	ID          int32     `json:"id"`
	Status      JobStatus `json:"status"`
	Attempts    int       `json:"attempts"`
	Kind        string    `json:"kind"`
	EncodedArgs []byte    `json:"args"`
}

type JobRow struct {
	JobInfo
	CreatedAt   time.Time          `json:"created_at"`
	ScheduledAt pgtype.Timestamptz `json:"scheduled_at"`
	Errors      []AttemptError     `json:"errors"`
}

type AttemptError struct {
	At    time.Time `json:"at"`
	Error string    `json:"error"`
}

type JobStatus uint8

const (
	JobStatusQueued     JobStatus = 0
	JobStatusBlocked    JobStatus = 1
	JobStatusReady      JobStatus = 2
	JobStatusRunning    JobStatus = 3
	JobStatusCompleted  JobStatus = 4
	JobStatusErrorRetry JobStatus = 5
	JobStatusFailed     JobStatus = 6
)

func (j JobStatus) String() string {
	switch j {
	case JobStatusQueued:
		return "QUEUE"
	case JobStatusBlocked:
		return "BLOCK"
	case JobStatusReady:
		return "READY"
	case JobStatusRunning:
		return "RUN"
	case JobStatusCompleted:
		return "DONE"
	case JobStatusErrorRetry:
		return "ERROR"
	case JobStatusFailed:
		return "FAIL"
	}
	return "Unknown (" + strconv.Itoa(int(j)) + ")"
}
