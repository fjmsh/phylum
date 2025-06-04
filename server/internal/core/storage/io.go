package storage

import (
	"io"
)

type callbackWriteCloser struct {
	dest          io.WriteCloser
	closeCallback func(error) error
}

func (c *callbackWriteCloser) Write(p []byte) (n int, err error) {
	n, err = c.dest.Write(p)
	return
}

func (c *callbackWriteCloser) Close() error {
	err := c.dest.Close()
	return c.closeCallback(err)
}
