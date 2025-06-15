package steve

import (
	"context"
	"time"
)

// Worker is an interface that can perform a job with args of type T.
// Workers must be registered with the client using the AddWorker function.
type Worker[T JobArgs] interface {
	// Timeout is the maximum amount of time the job is allowed to run before
	// its context is cancelled. A timeout of zero (the default) means the job
	// will inherit the Client-level timeout. A timeout of -1 means the job's
	// context will never time out.
	Timeout(job *Job[T]) time.Duration

	// Work performs the job and returns an error if the job failed. The context
	// will be configured with a timeout according to the worker settings and may
	// be cancelled for other reasons.
	//
	// If no error is returned, the job is assumed to have succeeded and will be
	// marked completed.
	//
	// It is important for any worker to respect context cancellation to enable
	// the client to respond to shutdown requests; there is no way to cancel a
	// running job that does not respect context cancellation, other than
	// terminating the process.
	Work(ctx context.Context, job *Job[T]) error
}

// WorkerDefaults is an empty struct that can be embedded in your worker
// struct to make it fulfill the Worker interface with default values.
type WorkerDefaults[T JobArgs] struct{}

// Timeout returns the job-specific timeout. Override this method to set a
// job-specific timeout, otherwise the Client-level timeout will be applied.
func (w WorkerDefaults[T]) Timeout(*Job[T]) time.Duration { return 0 }

// workFunc implements JobArgs and is used to wrap a function given to WorkFunc.
type workFunc[T JobArgs] struct {
	WorkerDefaults[T]
	kind string
	f    func(context.Context, *Job[T]) error
}

func (wf *workFunc[T]) Kind() string {
	return wf.kind
}

func (wf *workFunc[T]) Work(ctx context.Context, job *Job[T]) error {
	return wf.f(ctx, job)
}

// WorkFunc wraps a function to implement the Worker interface. A job args
// struct implementing JobArgs will still be required to specify a Kind.
//
// For example:
//
//	river.AddWorker(workers, river.WorkFunc(func(ctx context.Context, job *river.Job[WorkFuncArgs]) error {
//		fmt.Printf("Message: %s", job.Args.Message)
//		return nil
//	}))
func WorkFunc[T JobArgs](f func(context.Context, *Job[T]) error) Worker[T] {
	return &workFunc[T]{f: f, kind: (*new(T)).Kind()}
}
