package steve

import (
	"time"
)

// Job represents a single unit of work, holding both the arguments and
// information for a job with args of type T.
type Job[T JobArgs] struct {
	*JobRow

	// Args are the arguments for the job.
	Args T
}

// JobArgs is an interface that represents the arguments for a job of type T.
// These arguments are serialized into JSON and stored in the database.
//
// The struct is serialized using `encoding/json`. All exported fields are
// serialized, unless skipped with a struct field tag.
type JobArgs interface {
	// Kind is a string that uniquely identifies the type of job. This must be
	// provided on your job arguments struct. Jobs are identified by a string
	// instead of being based on type names so that previously inserted jobs
	// can be worked across deploys even if job/worker types are renamed.
	//
	// Kinds should be formatted without spaces like `my_custom_job`,
	// `mycustomjob`, or `my-custom-job`. Many special characters like colons,
	// dots, hyphens, and underscores are allowed, but those like spaces and
	// commas, which would interfere with UI functionality, are invalid.
	//
	// After initially deploying a job, it's generally not safe to rename its
	// kind (unless the database is completely empty) because River won't know
	// which worker should work the old kind. Job kinds can be renamed safely
	// over multiple deploys using the JobArgsWithKindAliases interface.
	Kind() string
}

// JobRow contains the properties of a job that are persisted to the database.
// Use of `Job[T]` will generally be preferred in user-facing code like worker
// interfaces.
type JobRow struct {
	// ID of the job. Generated as part of a Postgres sequence and generally
	// ascending in nature, but there may be gaps in it as transactions roll
	// back.
	ID int64

	// Attempt is the attempt number of the job. Jobs are inserted at 0, the
	// number is incremented to 1 the first time work its worked, and may
	// increment further if it errors.
	Attempt int

	// AttemptedAt is the time that the job was last worked. Starts out as `nil`
	// on a new insert.
	AttemptedAt *time.Time

	// CreatedAt is when the job row was created.
	CreatedAt time.Time

	// EncodedArgs is the job's JobArgs encoded as JSON.
	EncodedArgs []byte

	// Errors is a set of errors that occurred when the job was worked, one for
	// each attempt. Ordered from earliest error to the latest error.
	Errors []AttemptError

	// FinalizedAt is the time at which the job was "finalized", meaning it was
	// either completed successfully or errored for the last time such that
	// it'll no longer be retried.
	FinalizedAt *time.Time

	// Kind uniquely identifies the type of job and instructs which worker
	// should work it. It is set at insertion time via `Kind()` on the
	// `JobArgs`.
	Kind string

	// MaxAttempts is the maximum number of attempts that the job will be tried
	// before it errors for the last time and will no longer be worked.
	//
	// Extracted (in order of precedence) from job-specific InsertOpts
	// on Insert, from the worker level InsertOpts from JobArgsWithInsertOpts,
	// or from a client's default value.
	MaxAttempts int

	// State is the state of job like `available` or `completed`. Jobs are
	// `available` when they're first inserted.
	State JobState
}

type AttemptError struct {
	At      time.Time `json:"at"`
	Attempt int       `json:"attempt"`
	Error   string    `json:"error"`
}

// JobState is the state of a job. Jobs start their lifecycle as
// JobStateAvailable, and if all goes well, transition to JobStateCompleted
// after they're worked.
type JobState string

const (
	// JobStateAvailable is the state for jobs that are immediately eligible to
	// be worked.
	JobStateAvailable JobState = "available"

	// JobStateCancelled is the state for jobs that have been manually cancelled
	// by user request.
	JobStateCancelled JobState = "cancelled"

	// JobStateCompleted is the state for jobs that have successfully run to
	// completion.
	JobStateCompleted JobState = "completed"

	// JobStateDiscarded is the state for jobs that have errored enough times
	// that they're no longer eligible to be retried. Manual user invention
	// is required for them to be tried again.
	JobStateDiscarded JobState = "discarded"

	// JobStatePending is a state for jobs to be parked while waiting for some
	// external action before they can be worked. Jobs in pending will never be
	// worked or deleted unless moved out of this state by the user.
	JobStatePending JobState = "pending"

	// JobStateRetryable is the state for jobs that have errored, but will be
	// retried.
	//
	// The job scheduler service changes them to JobStateAvailable when they're
	// ready to be worked (their `scheduled_at` timestamp comes due).
	//
	// Jobs that will be retried very soon in the future may be changed to
	// JobStateAvailable immediately instead of JobStateRetryable so that they
	// don't have to wait for the job scheduler to run.
	JobStateRetryable JobState = "retryable"

	// JobStateRunning are jobs which are actively running.
	//
	// If River can't update state of a running job (in the case of a program
	// crash, underlying hardware failure, or job that doesn't return from its
	// Work function), that job will be left as JobStateRunning, and will
	// require a pass by the job rescuer service to be set back to
	// JobStateAvailable and be eligible for another run attempt.
	JobStateRunning JobState = "running"
)
