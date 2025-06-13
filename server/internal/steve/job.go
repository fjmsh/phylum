package steve

import (
	"time"
)

type Job[T JobArgs] struct {
	*JobRow
	Args T
}

type JobArgs interface {
	Kind() string
}

type JobRow struct {
	ID          int32          `json:"id"`
	State       JobState       `json:"state"`
	Attempt     int            `json:"attempt"`
	CreatedAt   time.Time      `json:"created_at"`
	AttemptedAt *time.Time     `json:"attempted_at"`
	FinalizedAt *time.Time     `json:"finalized_at"`
	EncodedArgs []byte         `json:"args"`
	Errors      []AttemptError `json:"errors"`
	Kind        string         `json:"kind"`
}

type AttemptError struct {
	At      time.Time `json:"at"`
	Attempt int       `json:"attempt"`
	Error   string    `json:"error"`
}

type JobState uint8

const (
	JobStateQueued        JobState = 0
	JobStateRunning       JobState = 1
	JobStateCompleted     JobState = 2
	JobStateAwaitingRetry JobState = 3
	JobStateFailed        JobState = 4
	JobStateCancelled     JobState = 5
)
