package steve

import (
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
	Attempt     int       `json:"attempt"`
	EncodedArgs []byte    `json:"args"`
	Kind        string    `json:"kind"`
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
	JobStatusQueued    JobStatus = 0
	JobStatusBlocked   JobStatus = 1
	JobStatusReady     JobStatus = 2
	JobStatusRunning   JobStatus = 3
	JobStatusCompleted JobStatus = 4
	JobStatusScheduled JobStatus = 5
	JobStatusFailed    JobStatus = 6
)
