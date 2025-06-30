package storage

import "errors"

var drivers = map[string]Driver{
	"local": {
		Name:        "local",
		Description: "Local Filesystem",
		Params:      []string{"root"},
		Create: func(name string, params map[string]string) (Backend, error) {
			return createLocalBackend(name, params)
		},
	},
	"minio": {
		Name:        "minio",
		Description: "MinIO (S3-compatible)",
		Params:      []string{"endpoint", "key_id", "key", "bucket_name", "prefix"},
		Create:      createMinioBackend,
	},
}

type Driver struct {
	Name        string
	Description string
	Params      []string
	Create      func(name string, params map[string]string) (Backend, error)
}

func ListDrivers() []Driver {
	d := make([]Driver, 0, len(drivers))
	for _, v := range drivers {
		d = append(d, v)
	}
	return d
}

func FindDriver(driverName string) (Driver, error) {
	if driver, ok := drivers[driverName]; ok {
		return driver, nil
	}
	return Driver{}, errors.New("unrecognized storage driver: " + driverName)
}
