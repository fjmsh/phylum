package storage

import (
	"hash"
)

type hasher struct {
	rwc           ReadWriteSeekCloser
	len           int
	sum           hash.Hash
	closeCallback func(int, hash.Hash, error) error
}

func (c *hasher) Read(p []byte) (n int, err error) {
	return c.rwc.Read(p)
}

func (c *hasher) Seek(offset int64, whence int) (int64, error) {
	return c.rwc.Seek(offset, whence)
}

func (c *hasher) Write(p []byte) (n int, err error) {
	n, err = c.rwc.Write(p)
	c.sum.Write(p)
	c.len += n
	return
}

func (c *hasher) Close() error {
	return c.closeCallback(c.len, c.sum, c.rwc.Close())
}
