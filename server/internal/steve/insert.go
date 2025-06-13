package steve

import (
	"context"

	"github.com/jackc/pgx/v5"
)

func insertJobs(ctx context.Context, tx pgx.Tx, arg []insertJobParams) (int64, error) {
	return tx.CopyFrom(ctx, []string{"jobs"}, []string{"kind", "args"}, &iteratorForInsertJobParams{rows: arg})
}

// For bulk insert
type insertJobParams struct {
	Kind        string
	EncodedArgs []byte
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
