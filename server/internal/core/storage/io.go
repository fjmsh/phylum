package storage

import (
	"hash"
	"io"

	"github.com/gabriel-vasile/mimetype"
)

type hasher struct {
	dest          io.WriteCloser
	len           int
	sum           hash.Hash
	contents      []byte
	closeCallback func(int, hash.Hash, string) error
}

func (c *hasher) Write(p []byte) (n int, err error) {
	n, err = c.dest.Write(p)
	c.len += n
	if c.sum != nil {
		c.sum.Write(p)
	}
	remain := min(cap(c.contents)-len(c.contents), len(p))
	if remain > 0 {
		c.contents = append(c.contents, p[:remain]...)
	}
	return
}

func min(a, b int) int {
	if b < a {
		return b
	}
	return a

}

func (c *hasher) Close() error {
	if err := c.dest.Close(); err != nil {
		return err
	}
	return c.closeCallback(c.len, c.sum, mimetype.Detect(c.contents).String())
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
