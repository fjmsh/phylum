package img

import (
	"errors"

	"github.com/asticode/go-astiav"
	"github.com/davidbyttow/govips/v2/vips"
)

func processAV(name, path string) (Res, error) {
	formatContext := astiav.AllocFormatContext()
	if formatContext == nil {
		return 0, errors.New("failed to allocate format context")
	}
	defer formatContext.Free()

	if err := formatContext.OpenInput(path, nil, nil); err != nil {
		return 0, errors.New("failed to open input: " + err.Error())
	}
	defer formatContext.CloseInput()

	if err := formatContext.FindStreamInfo(nil); err != nil {
		return 0, errors.New("failed to find stream info: " + err.Error())
	}

	var stream *astiav.Stream
	var codec *astiav.Codec
	var codecContext *astiav.CodecContext
	for _, is := range formatContext.Streams() {
		if is.CodecParameters().MediaType() == astiav.MediaTypeVideo &&
			(is.DispositionFlags()&astiav.DispositionFlags(astiav.DispositionFlagAttachedPic) != 0) {
			stream = is
			if codec = astiav.FindDecoder(is.CodecParameters().CodecID()); codec == nil {
				return 0, errors.New("failed to find decoder for attached pic")
			}
		}
	}

	if stream == nil {
		if s, c, err := formatContext.FindBestStream(astiav.MediaTypeVideo, -1, -1); err != nil {
			return 0, nil
		} else {
			stream = s
			codec = c
			time := int64(float64(s.Duration()) * 0.2)
			formatContext.SeekFrame(stream.Index(), time, astiav.NewSeekFlags())
		}
	}

	// Allocate codec context
	if codecContext = astiav.AllocCodecContext(codec); codecContext == nil {
		return 0, errors.New("failed to allocate codec context")
	}
	defer codecContext.Free()

	// Update codec context
	if err := stream.CodecParameters().ToCodecContext(codecContext); err != nil {
		return 0, errors.New("failed to update codec context: " + err.Error())
	}
	// Open codec context
	if err := codecContext.Open(codec, nil); err != nil {
		return 0, errors.New("failed to open codec context: " + err.Error())
	}

	// Allocate packet
	pkt := astiav.AllocPacket()
	defer pkt.Free()

	// Allocate frame
	f := astiav.AllocFrame()
	defer f.Free()

	for {
		if stop, err := func() (bool, error) {
			if err := formatContext.ReadFrame(pkt); err != nil {
				if !errors.Is(err, astiav.ErrEof) {
					err = errors.New("failed to read frame: " + err.Error())
				}
				return true, err
			}
			defer pkt.Unref()

			if pkt.StreamIndex() != stream.Index() {
				return false, nil
			}

			if err := codecContext.SendPacket(pkt); err != nil {
				return true, errors.New("failed to send packet to codec: " + err.Error())
			}

			if err := codecContext.ReceiveFrame(f); err != nil {
				if errors.Is(err, astiav.ErrEagain) {
					// More frames needed
					return false, nil
				} else {
					err = errors.New("failed to receive frame from codec: " + err.Error())
				}
				return true, err
			}
			defer f.Unref()

			if img, err := f.Data().GuessImageFormat(); err != nil {
				return true, errors.New("failed to guess image format: " + err.Error())
			} else if err := f.Data().ToImage(img); err != nil {
				return true, errors.New("failed to convert to image: " + err.Error())
			} else if v, err := vips.NewImageFromGoImage(img); err != nil {
				return true, errors.New("failed to create vips image: " + err.Error())
			} else {
				defer v.Close()
				return true, scaleAndSaveImages(v, name, ResAll)
			}
		}(); stop {
			if err != nil {
				if errors.Is(err, astiav.ErrEof) {
					err = nil
				}
				return 0, err
			}
			return ResAll, nil
		}
	}
}
