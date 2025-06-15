package steve

import (
	"math"
	"time"

	"github.com/jackc/pgx/v5/pgtype"
)

func computeBackoff(failedAttempts int) (t pgtype.Timestamptz) {
	if failedAttempts >= maxAttempts {
		return
	}
	// 6s, 36s, 216s (3.5m), 1276 (21m), ~2h, ~12h
	t.Time = time.Now().Add(time.Duration(math.Pow(6, float64(failedAttempts+1))) * time.Second)
	t.Valid = true
	return
}
