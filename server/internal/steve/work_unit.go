package steve

import (
	"context"
	"encoding/json"
	"time"
)

// WorkUnit provides an interface to a struct that wraps a job to be done
// combined with a work function that can execute it. Its main purpose is to
// wrap a struct that contains generic types (like a Worker[T] that needs to be
// invoked with a Job[T]) in such a way as to make it non-generic so that it can
// be used in other non-generic code like jobExecutor.
type WorkUnit interface {
	Timeout() time.Duration
	Work(ctx context.Context) error
}

// WorkUnitFactory provides an interface to a struct that can generate a
// workUnit, a wrapper around a job to be done combined with a work function
// that can execute it.
type WorkUnitFactory interface {
	// Make a workUnit, which wraps a job to be done and work function that can
	// execute it.
	MakeUnit(*JobInfo) (WorkUnit, error)
}

// typedWorkUnitFactory wraps a Worker to implement WorkUnitFactory.
type typedWorkUnitFactory[T JobArgs] struct {
	worker Worker[T]
}

func (w *typedWorkUnitFactory[T]) MakeUnit(info *JobInfo) (WorkUnit, error) {
	unit := &typedWorkUnit[T]{worker: w.worker}
	return unit, json.Unmarshal(info.EncodedArgs, unit.job.Args)
}

// typedWorkUnit implements workUnit for a job and Worker.
type typedWorkUnit[T JobArgs] struct {
	job    *Job[T] // not set until after UnmarshalJob is invoked
	worker Worker[T]
}

func (w *typedWorkUnit[T]) Timeout() time.Duration         { return w.worker.Timeout(w.job) }
func (w *typedWorkUnit[T]) Work(ctx context.Context) error { return w.worker.Work(ctx, w.job) }
