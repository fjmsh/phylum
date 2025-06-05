package core

import (
	"crypto/sha256"
	"hash"
	"io"
	"strings"

	"github.com/gabriel-vasile/mimetype"
)

type contentPropsComputer struct {
	dest            io.WriteCloser
	len             int
	sum             hash.Hash
	contents        []byte
	successCallback func(int, hash.Hash, string) error
}

func computeProps(dest io.WriteCloser, successCallback func(int, hash.Hash, string) error) *contentPropsComputer {
	return &contentPropsComputer{
		dest:            dest,
		sum:             sha256.New(),
		contents:        make([]byte, 0, 3072),
		successCallback: successCallback,
	}
}

func (c *contentPropsComputer) Write(p []byte) (n int, err error) {
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

func (c *contentPropsComputer) Close() error {
	if err := c.dest.Close(); err != nil {
		return err
	}
	return c.successCallback(c.len, c.sum, mimetype.Detect(c.contents).String())
}

func CheckResourceNameInvalid(s string) bool {
	return s == "" || s == "." || s == ".." || strings.ContainsFunc(s, func(r rune) bool {
		return r == 0 || r == '/'
	})
}
