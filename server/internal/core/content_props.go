package core

import (
	"crypto/sha256"
	"encoding/hex"
	"io"

	"github.com/abema/go-mp4"
	"github.com/gabriel-vasile/mimetype"
)

type contentProps struct {
	size      int64
	sha566Sum string
	mimeType  string
}

func computeProps(r io.ReadSeeker) (props contentProps, err error) {
	props.size, err = r.Seek(0, io.SeekEnd)
	props.sha566Sum, err = computeSha256(r)
	if err != nil {
		return
	}
	props.mimeType, err = guessMimeType(r)
	if err != nil {
		return
	}
	return
}

func computeSha256(r io.ReadSeeker) (string, error) {
	hash := sha256.New()
	r.Seek(0, io.SeekStart)
	if _, err := io.Copy(hash, r); err != nil {
		return "", err
	}
	return hex.EncodeToString(hash.Sum(nil)), nil
}

func guessMimeType(r io.ReadSeeker) (string, error) {
	const typeDetectBufferSize = 3072
	contents := make([]byte, 0, typeDetectBufferSize)

	r.Seek(0, io.SeekStart)
	buf := contents
	for {
		if r, err := r.Read(buf); err != nil {
			if err != io.EOF {
				return "", err
			} else {
				break
			}
		} else {
			buf = buf[r:]
		}
	}
	mimeType := mimetype.Detect(contents).String()
	if mimeType == "video/mp4" && isMP4Audio(r) {
		mimeType = "audio/mp4"
	}

	return mimeType, nil
}

func isMP4Audio(r io.ReadSeeker) bool {
	r.Seek(0, io.SeekStart)
	if box, err := mp4.ExtractBoxWithPayload(r, nil, mp4.BoxPath{
		mp4.BoxTypeMoov(),
		mp4.BoxTypeTrak(),
		mp4.BoxTypeMdia(),
		mp4.BoxTypeHdlr(),
	}); err == nil && len(box) == 1 {
		hdlr := box[0].Payload.(*mp4.Hdlr)
		if hdlr.HandlerType == boxTypeSoun {
			return true
		}
	}
	return false
}
