package storage

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

type s3Storage struct {
	name       string
	client     *s3.Client
	bucketName string
	prefix     string
}

func createS3Backend(name string, params map[string]string) (Backend, error) {
	if params["endpoint"] == "" {
		return nil, errors.New("endpoint not provided")
	}
	if params["region"] == "" {
		return nil, errors.New("region not provided")
	}
	if params["key_id"] == "" {
		return nil, errors.New("key id not provided")
	}
	if params["key"] == "" {
		return nil, errors.New("access key not provided")
	}
	if params["bucket_name"] == "" {
		return nil, errors.New("bucket name not provided")
	}

	creds := credentials.NewStaticCredentialsProvider(params["key_id"], params["key"], "")
	config, err := config.LoadDefaultConfig(context.Background(),
		config.WithCredentialsProvider(creds),
		config.WithRegion(params["region"]), // Your B2 region
		config.WithEndpointResolverWithOptions(aws.EndpointResolverWithOptionsFunc(
			func(service, region string, options ...interface{}) (aws.Endpoint, error) {
				return aws.Endpoint{
					URL:           params["endpoint"],
					SigningRegion: params["region"],
				}, nil
			},
		)),
	)
	if err != nil {
		return nil, err
	}

	client := s3.NewFromConfig(config, func(o *s3.Options) {
		o.UsePathStyle = true // Critical for Backblaze compatibility
	})

	return s3Storage{name: name, client: client, bucketName: params["bucket_name"], prefix: params["prefix"]}, nil
}

func (s s3Storage) Name() string {
	return s.name
}

func (s s3Storage) OpenRead(name string, start, length int) (io.ReadCloser, error) {
	var rangeInput *string
	if length != -1 {
		end := start + length
		switch {
		case start == 0 && end < 0:
			s := fmt.Sprintf("bytes=%d", end)
			rangeInput = &s
		case 0 < start && end == 0:
			s := fmt.Sprintf("bytes=%d-", start)
			rangeInput = &s
		case 0 <= start && start <= end:
			s := fmt.Sprintf("bytes=%d-%d", start, end)
			rangeInput = &s
		default:
			return nil, fmt.Errorf("Invalid range specified: start=%d end=%d", start, end)
		}
	}

	key := s.prefix + name
	obj, err := s.client.GetObject(context.Background(), &s3.GetObjectInput{
		Bucket: &s.bucketName,
		Key:    &key,
		Range:  rangeInput,
	})
	if err != nil {
		return nil, err
	}
	return obj.Body, nil
}

func (s s3Storage) Copy(ctx context.Context, src Backend, srcName, destName string) error {
	if src == s && srcName == destName {
		return errors.New("cannot copy to self")
	}
	var localPath string
	if l, ok := src.(LocalBackend); ok {
		localPath = l.Path(srcName)
	} else {
		f, err := os.CreateTemp(tempDir, "phylum-*")
		if err != nil {
			return err
		}
		defer func() {
			os.Remove(f.Name())
		}()

		in, err := src.OpenRead(srcName, 0, -1)
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

	fileReader, err := os.Open(localPath)
	if err != nil {
		return err
	}
	defer fileReader.Close()

	key := s.prefix + destName
	_, err = s.client.PutObject(context.Background(), &s3.PutObjectInput{
		Bucket: &s.bucketName,
		Key:    &key,
		Body:   fileReader,
	})
	return err
}

func (s s3Storage) Delete(name string) error {
	key := s.prefix + name
	_, err := s.client.DeleteObject(context.Background(), &s3.DeleteObjectInput{
		Bucket: &s.bucketName,
		Key:    &key,
	})
	return err
}

func (s s3Storage) DeleteAll(names []string) []error {
	objs := make([]types.ObjectIdentifier, len(names))
	for i, name := range names {
		key := s.prefix + name
		objs[i] = types.ObjectIdentifier{Key: &key}
	}
	result, err := s.client.DeleteObjects(context.Background(), &s3.DeleteObjectsInput{
		Bucket: &s.bucketName,
		Delete: &types.Delete{
			Objects: objs,
		},
	})
	if err != nil {
		return []error{err}
	}
	errs := make([]error, len(result.Errors))
	for i, err := range result.Errors {
		errs[i] = fmt.Errorf("failed to delete %s(%s): %s  ", *err.Key, *err.Code, *err.Message)
	}
	return errs
}

func (s s3Storage) String() string {
	return fmt.Sprintf("minio (endpoint: %s, bucket: %s, prefix: %s)", *s.client.Options().BaseEndpoint, s.bucketName, s.prefix)
}
