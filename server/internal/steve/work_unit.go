package steve

import (
	"context"
	"encoding/json"
	"time"
)

// workUnit provides an interface to a struct that wraps a job to be done
// combined with a work function that can execute it. Its main purpose is to
// wrap a struct that contains generic types (like a Worker[T] that needs to be
// invoked with a Job[T]) in such a way as to make it non-generic so that it can
// be used in other non-generic code like jobExecutor.
type workUnit interface {
	Timeout() time.Duration
	Sequences() []string
	Blocking() bool
	MaxAttempts() int
	Work(ctx context.Context) error
}

// workUnitFactory provides an interface to a struct that can generate a
// workUnit, a wrapper around a job to be done combined with a work function
// that can execute it.
type workUnitFactory interface {
	// Make a workUnit, which wraps a job to be done and work function that can
	// execute it.
	makeUnit(*JobInfo) (workUnit, error)
}

// typedWorkUnitFactory wraps a Worker to implement WorkUnitFactory.
type typedWorkUnitFactory[T JobArgs] struct {
	worker Worker[T]
}

func (w *typedWorkUnitFactory[T]) makeUnit(info *JobInfo) (workUnit, error) {
	var job Job[T]
	job.JobInfo = info
	unit := &typedWorkUnit[T]{worker: w.worker, job: &job}
	return unit, json.Unmarshal(info.EncodedArgs, &job.Args)
}

// typedWorkUnit implements workUnit for a job and Worker.
type typedWorkUnit[T JobArgs] struct {
	job    *Job[T]
	worker Worker[T]
}

func (w *typedWorkUnit[T]) Timeout() time.Duration         { return w.worker.Timeout(w.job) }
func (w *typedWorkUnit[T]) Sequences() []string            { return w.job.Args.Sequences() }
func (w *typedWorkUnit[T]) Blocking() bool                 { return w.job.Args.Blocking() }
func (w *typedWorkUnit[T]) MaxAttempts() int               { return w.job.Args.MaxAttempts() }
func (w *typedWorkUnit[T]) Work(ctx context.Context) error { return w.worker.Work(ctx, w.job) }
