package storage

import (
	"hash"
	"io"
)

type hasher struct {
	rwc           io.ReadWriteCloser
	len           int
	sum           hash.Hash
	closeCallback func(int, hash.Hash, error) error
}

func (c *hasher) Read(p []byte) (n int, err error) {
	return c.rwc.Read(p)
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
