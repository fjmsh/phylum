package storage

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"

	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

var ErrRangeNotSupported = errors.New("byte range not suppoered")

type minioStorage struct {
	name       string
	client     *minio.Client
	bucketName string
	prefix     string
}

func createMinioBackend(name string, params map[string]string) (Backend, error) {
	if params["endpoint"] == "" {
		return nil, errors.New("endpoint not provided")
	}
	if params["key_id"] == "" {
		return nil, errors.New("key id not provided")
	}
	if params["access_key"] == "" {
		return nil, errors.New("access key not provided")
	}
	if params["bucket_name"] == "" {
		return nil, errors.New("bucket name not provided")
	}

	client, err := minio.New(params["endpoint"], &minio.Options{
		Creds:  credentials.NewStaticV4(params["key_id"], params["access_key"], ""),
		Secure: true,
	})
	if err != nil {
		return nil, err
	}
	return minioStorage{name: name, client: client, bucketName: params["bucket_name"], prefix: params["prefix"]}, nil
}

func (s minioStorage) Name() string {
	return s.name
}

func (s minioStorage) OpenRead(name string, start, length int) (io.ReadCloser, error) {
	// TODO: Range
	if r, err := s.client.GetObject(context.Background(), s.bucketName, s.prefix+name, minio.GetObjectOptions{}); err != nil {
		return nil, err
	} else {
		return r, ErrRangeNotSupported
	}
}

func (s minioStorage) Copy(name string, src Backend) error {
	if src == s {
		return errors.New("cannot copy to self")
	}
	var localPath string
	if l, ok := src.(LocalBackend); ok {
		localPath = l.path(name)
	} else {
		f, err := os.CreateTemp(tempDir, "phylum-*")
		if err != nil {
			return err
		}
		defer func() {
			os.Remove(f.Name())
		}()

		in, err := src.OpenRead(name, 0, -1)
		if err != nil {
			return err
		}
		defer in.Close()

		_, copyErr := io.Copy(f, in)
		closeErr := f.Close()
		if copyErr != nil {
			return copyErr
		}
		if closeErr != nil {
			return closeErr
		}
		localPath = f.Name()
	}
	_, err := s.client.FPutObject( //TODO: #context
		context.Background(),
		s.bucketName,
		s.prefix+name,
		localPath,
		minio.PutObjectOptions{},
	)
	return err
}

func (s minioStorage) Delete(name string) error {
	return s.client.RemoveObject(context.Background(), s.bucketName, s.prefix+name, minio.RemoveObjectOptions{})
}

func (s minioStorage) DeleteAll(names []string) []error {
	objs := make(chan minio.ObjectInfo)
	go func() {
		defer close(objs)
		for _, name := range names {
			objs <- minio.ObjectInfo{
				Key: s.prefix + name,
			}
		}
	}()
	errChan := s.client.RemoveObjects(context.Background(), s.bucketName, objs, minio.RemoveObjectsOptions{})
	errs := make([]error, 0)
	for err := range errChan {
		errs = append(errs, err.Err)
	}
	return errs
}

func (s minioStorage) String() string {
	return fmt.Sprintf("minio (endpoint: %s, bucket: %s, prefix: %s)", s.client.EndpointURL(), s.bucketName, s.prefix)
}

// type progressReader struct {
// 	cur, len int
// 	callback func()
// }

// func (r *progressReader) Read(p []byte) (n int, err error) {
// 	max := r.len - r.cur
// 	size := len(p)
// 	if size > max {
// 		size = max
// 	}
// 	r.cur += size
// 	if r.cur == r.len && size == 0 {
// 		r.callback()
// 	}
// 	return size, nil
// }
