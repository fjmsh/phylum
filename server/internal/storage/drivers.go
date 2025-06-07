package storage

import "errors"

var drivers = map[string]Driver{
	"local": {
		Params: []string{"root"},
		Create: func(name string, params map[string]string) (Backend, error) {
			return createLocalBackend(name, params)
		},
	},
	"minio": {
		Params: []string{"endpoint", "key_id", "access_key", "bucket_name", "prefix"},
		Create: createMinioBackend,
	},
}

type Driver struct {
	Params []string
	Create func(name string, params map[string]string) (Backend, error)
}

func FindDriver(driverName string) (Driver, error) {
	if driver, ok := drivers[driverName]; ok {
		return driver, nil
	}
	return Driver{}, errors.New("unrecognized storage driver: " + driverName)
}
