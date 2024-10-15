package storage

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"

	"github.com/google/uuid"
	"github.com/minio/minio-go/v7"
	"github.com/minio/minio-go/v7/pkg/credentials"
)

type minioStorage struct {
	name       string
	client     *minio.Client
	tmp        string
	bucketName string
	prefix     string
}

func newMinioStorage(
	name,
	endpoint,
	keyId,
	accessKey,
	tmp,
	bucketName,
	prefix string) (Backend, error) {
	if endpoint == "" {
		return nil, errors.New("minio endpoint not provided")
	}
	if keyId == "" {
		return nil, errors.New("minio key id not provided")
	}
	if accessKey == "" {
		return nil, errors.New("minio access key not provided")
	}
	if tmp == "" {
		return nil, errors.New("minio tmp not provided")
	}
	if bucketName == "" {
		return nil, errors.New("minio bucket name not provided")
	}
	err := os.MkdirAll(tmp, 0750)
	if err != nil {
		return nil, err
	}
	client, err := minio.New(endpoint, &minio.Options{
		Creds:  credentials.NewStaticV4(keyId, accessKey, ""),
		Secure: true,
	})
	if err != nil {
		return nil, err
	}
	return minioStorage{name: name, client: client, tmp: tmp, bucketName: bucketName, prefix: prefix}, nil
}

func (s minioStorage) Name() string {
	return s.name
}

func (s minioStorage) OpenRead(id uuid.UUID, start, length int64) (io.ReadCloser, error) {
	// TODO: Range
	return s.client.GetObject(context.Background(), s.bucketName, s.prefix+id.String(), minio.GetObjectOptions{})
}

func (s minioStorage) OpenWrite(id uuid.UUID) (io.WriteCloser, error) {
	path := filepath.Join(s.tmp, id.String())
	file, err := os.OpenFile(path, os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0640)
	if err != nil {
		return nil, err
	}
	return &callbackWriteCloser{dest: file, closeCallback: func(len int) error {
		_, err = s.client.FPutObject(context.Background(), s.bucketName, s.prefix+id.String(), path, minio.PutObjectOptions{Progress: &progressReader{len: len, callback: func() {
			os.Remove(path)
		}}})
		return err
	}}, nil
}

func (s minioStorage) Delete(id uuid.UUID) error {
	return s.client.RemoveObject(context.Background(), s.bucketName, s.prefix+id.String(), minio.RemoveObjectOptions{})
}

func (s minioStorage) DeleteAll(ids uuid.UUIDs) []error {
	objs := make(chan minio.ObjectInfo)
	go func() {
		defer close(objs)
		for _, id := range ids {
			objs <- minio.ObjectInfo{
				Key: s.prefix + id.String(),
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
	return fmt.Sprintf("minio (endpoint: %s, bucket: %s, prefix: %s, tmp: %s)", s.client.EndpointURL(), s.bucketName, s.prefix, s.tmp)
}

type progressReader struct {
	cur, len int
	callback func()
}

func (r *progressReader) Read(p []byte) (n int, err error) {
	max := r.len - r.cur
	size := len(p)
	if size > max {
		size = max
	}
	r.cur += size
	if r.cur == r.len && size == 0 {
		r.callback()
	}
	return size, nil
}
