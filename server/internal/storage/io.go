package storage

import (
	"hash"
	"io"
)

type hasher struct {
	dest          io.WriteCloser
	len           int
	sum           hash.Hash
	closeCallback func(int, hash.Hash) error
}

func (c *hasher) Write(p []byte) (n int, err error) {
	n, err = c.dest.Write(p)
	c.sum.Write(p)
	c.len += n
	return
}

func (c *hasher) Close() error {
	if err := c.dest.Close(); err != nil {
		return err
	}
	return c.closeCallback(c.len, c.sum)
}

type callbackWriteCloser struct {
	dest          io.WriteCloser
	len           int
	closeCallback func(int) error
}

func (c *callbackWriteCloser) Write(p []byte) (n int, err error) {
	n, err = c.dest.Write(p)
	c.len += n
	return
}

func (c *callbackWriteCloser) Close() error {
	if err := c.dest.Close(); err != nil {
		return err
	}
	return c.closeCallback(c.len)
}
