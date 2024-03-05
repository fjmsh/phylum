package storage

import (
	"hash"
	"io"
)

type hasher struct {
	file          io.ReadWriteCloser
	hash          hash.Hash
	len           **int
	closeCallback func(hash.Hash, int, error)
}

func (c hasher) Read(p []byte) (n int, err error) {
	return c.file.Read(p)
}

func (c hasher) Write(p []byte) (n int, err error) {
	n, err = c.file.Write(p)
	len := **c.len + n
	*c.len = &len
	c.hash.Write(p)
	return
}

func (c hasher) Close() error {
	err := c.file.Close()
	c.closeCallback(c.hash, **c.len, err)
	return err
}
