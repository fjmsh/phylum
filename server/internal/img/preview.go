package img

import (
	"errors"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/HugoSmits86/nativewebp"
	"github.com/asticode/go-astiav"
	"github.com/raitucarp/epub"
)

const maxImageSizeNoPreview = 256 * 1024

var quality uint8
var dir string
var tmp string

func Initialize(cfg Config) error {
	quality = cfg.Quality

	if filepath.IsAbs(cfg.Dir) {
		dir = cfg.Dir
	} else {
		dir = filepath.Join(storage.Root, cfg.Dir)
	}
	tmp = filepath.Join(dir, "tmp")

	if err := os.MkdirAll(tmp, 0o700); err != nil {
		return errors.New("failed to create img directory: " + err.Error())
	}

	return nil
}

func Open(name string, res Res) (io.ReadCloser, error) {
	return os.Open(filepath.Join(dir, name) + "-" + resSuffixes[res] + ".webp")
}

func Copy(src, dest string, imgRes Res) error {
	for res, s := range resSuffixes {
		if imgRes&res != 0 {
			if in, err := os.Open(filepath.Join(dir, src) + "-" + s + ".webp"); err != nil {
				return err
			} else if out, err := os.Create(filepath.Join(dir, dest) + "-" + s + ".webp"); err != nil {
				return err
			} else if _, err := io.Copy(out, in); err != nil {
				return err
			}
		}
	}
	return nil
}

func Delete(name string, imgRes Res) error {
	for res, s := range resSuffixes {
		if imgRes&res != 0 {
			if err := os.Remove(filepath.Join(dir, name) + "-" + s + ".webp"); err != nil {
				return err
			}
		}
	}
	return nil
}

func GetGenerator(mimeType string) func(string) (uint8, error) {
	if imageType, ok := strings.CutPrefix(mimeType, "image/"); ok {
		if _, ok := imageTypes[imageType]; ok {
			return func(path string) (uint8, error) { return processImage(path, false) }
		}
	}

	if ok := strings.HasPrefix(mimeType, "text/"); ok {
		return func(path string) (uint8, error) { return processText(path) }
	}
	if subType, ok := strings.CutPrefix(mimeType, "application/"); ok {
		if fn, ok := applicationTypes[subType]; ok {
			return fn
		}

		if strings.HasSuffix("+json", subType) || strings.HasSuffix("+xml", subType) {
			return processText
		}
	}
	return nil
}

func processApplicationImage(path string) (Res, error) {
	return processImage(path, true)
}

// processImage generates preview + thumbnail for images (and PDF).
// Preview is only generated if the image size is larger than 1M
// or if forcePreview is set to true (typically for non-image formats)
// like PDF and PS
func processImage(input string, forcePreview bool) (Res, error) {
	var generated Res
	stat, err := os.Stat(input)
	if err != nil {
		return 0, errors.New("failed to find input image: " + err.Error())
	}
	base := filepath.Base(input)
	src := input
	if forcePreview || stat.Size() > maxImageSizeNoPreview {
		if o, err := generateImagePreview(src, dir, base, quality); err != nil {
			return 0, err
		} else {
			src = o
		}
		generated |= ResLarge
	}

	if _, err := generateThumbnail(src, dir, base, quality); err != nil {
		return 0, err
	}
	generated |= ResThumbnail
	return generated, nil
}

// Generate thumbnail only for text using.
// A temporary document preview must be generated and then resized down
func processText(input string) (Res, error) {
	if err := generateTextPreview(input, tmp); err != nil {
		return 0, err
	}
	// No need to keep the full generated preview since we'll render
	// the text directly on the client using file contents
	base := filepath.Base(input)
	src := filepath.Join(tmp, base+".webp")
	defer os.Remove(src)

	if _, err := generateThumbnail(src, dir, base, quality); err != nil {
		return 0, err
	}
	return ResThumbnail, nil
}

func ProcessVideo(path string) (Res, error) {
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
				return 0, errors.New("failed to find decoder")
			}
		}
	}

	if stream == nil {
		if s, c, err := formatContext.FindBestStream(astiav.MediaTypeVideo, -1, -1); err != nil {
			return 0, errors.New("failed to find video stream: " + err.Error())
		} else {
			stream = s
			codec = c
			time := int64(float64(s.Duration()) * 0.2)
			fmt.Printf("Duration: %d\n", s.Duration())
			fmt.Printf("Seeking to %d\n", time)
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

	var generated Res
	for {
		if stop, err := func() (bool, error) {
			if err := formatContext.ReadFrame(pkt); err != nil {
				if errors.Is(err, astiav.ErrEof) {
					// Stream finished (and no suitable frames found)
					err = nil
					err = errors.New("TODO (remove): file finished")
				} else {
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
			} else {
				base := filepath.Base(path)
				large := filepath.Join(dir, base+"-"+resSuffixes[ResLarge]+".webp")
				var generated Res
				if f, err := os.Create(large); err != nil {
					return true, err
				} else if err := nativewebp.Encode(f, img, nil); err != nil {
					f.Close()
					return true, err
				} else {
					f.Close()
					generated |= ResLarge
					if _, err := generateThumbnail(large, dir, base, quality); err != nil {
						return true, err
					}
					generated |= ResThumbnail
					return true, nil
				}
			}

		}(); stop {
			return generated, err
		}
	}
}

func processEpub(path string) (Res, error) {
	if r, err := epub.OpenReader(path); err != nil {
		return 0, err
	} else if cover := r.Cover(); cover == nil {
		return 0, nil
	} else {
		base := filepath.Base(path)
		large := filepath.Join(dir, base+"-"+resSuffixes[ResLarge]+".webp")
		var generated Res
		if f, err := os.Create(large); err != nil {
			return 0, err
		} else if err := nativewebp.Encode(f, *cover, nil); err != nil {
			f.Close()
			return 0, err
		} else {
			f.Close()
			generated |= ResLarge
			if _, err := generateThumbnail(large, dir, base, quality); err != nil {
				return 0, err
			}
			generated |= ResThumbnail
			return generated, nil
		}
	}
}

// Generate preview and thumbnail for office documents.
func processDocument(input string) (Res, error) {
	if err := generateDocumentPreview(input, dir); err != nil {
		return 0, err
	}
	base := filepath.Base(input)
	out := filepath.Join(dir, base+".webp")
	src := filepath.Join(dir, base+"-"+resSuffixes[ResLarge]+".webp")
	if err := os.Rename(out, src); err != nil {
		return 0, errors.New("failed to rename document preview: " + err.Error())
	}

	if _, err := generateThumbnail(src, dir, base, quality); err != nil {
		return 0, err
	}
	return ResLarge | ResThumbnail, nil
}
