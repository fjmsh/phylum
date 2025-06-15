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
	At      time.Time `json:"at"`
	Attempt int       `json:"attempt"`
	Error   string    `json:"error"`
}

type JobStatus uint8

const (
	JobStatusQueued    JobStatus = 0
	JobStatusRunning   JobStatus = 1
	JobStatusCompleted JobStatus = 2
	JobStatusScheduled JobStatus = 3
	JobStatusFailed    JobStatus = 4
	JobStatusCancelled JobStatus = 5
)
