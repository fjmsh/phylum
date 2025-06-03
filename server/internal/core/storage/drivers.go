package storage

import "errors"

var drivers = map[string]Driver{
	"local": {
		Params: []string{"root"},
		Create: createLocalBackend,
	},
	"minio": {
		Params: []string{"endpoint", "key_id", "access_key", "tmp", "bucket_name", "prefix"},
		Create: createMinioBackend,
	},
}

type Driver struct {
	Params []string
	Create func(params map[string]string, validate bool) (Backend, error)
}

func FindDriver(driverName string) (Driver, error) {
	if driver, ok := drivers[driverName]; ok {
		return driver, nil
	}
	return Driver{}, errors.New("unrecognized storage driver: " + driverName)
}
