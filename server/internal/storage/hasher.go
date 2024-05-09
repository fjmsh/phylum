package storage

import (
	"errors"
	"hash"
	"io"
)

type hasher struct {
	dest          io.WriteCloser
	len           int
	sum           hash.Hash
	closeCallback func(int, hash.Hash, error) error
}

func (c *hasher) Read(p []byte) (n int, err error) {
	return 0, errors.New("read not supported")
}

func (c *hasher) Write(p []byte) (n int, err error) {
	n, err = c.dest.Write(p)
	c.sum.Write(p)
	c.len += n
	return
}

func (c *hasher) Seek(offset int64, whence int) (int64, error) {
	return 0, errors.New("seek not supported")
}

func (c *hasher) Close() error {
	return c.closeCallback(c.len, c.sum, c.dest.Close())
}
