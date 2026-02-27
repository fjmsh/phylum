package steve

import (
	"math"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

const defaultMaxAttempts = 6
const maxBackoffDelay = 7200 //2 hours

func computeNextAttempt(failedAttempts, maxAttempts int) (nextAttempt pgtype.Timestamptz) {
	if maxAttempts == 0 {
		maxAttempts = defaultMaxAttempts
	}
	if failedAttempts >= maxAttempts {
		return
	}
	// 6s, 36s, 216s (3.5m), 1276 (21m), ~2h, ~12h
	backoffDelay := math.Pow(6, float64(failedAttempts+1))
	if backoffDelay > maxBackoffDelay {
		backoffDelay = maxBackoffDelay
	}
	nextAttempt.Time = time.Now().Add(time.Duration(backoffDelay) * time.Second)
	nextAttempt.Valid = true
	return
}
