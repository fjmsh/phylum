package serve

import (
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/textproto"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
	"codeberg.org/shroff/phylum/server/internal/storage"
	"github.com/google/uuid"
)

var htmlReplacer = strings.NewReplacer(
	"&", "&amp;",
	"<", "&lt;",
	">", "&gt;",
	// "&#34;" is shorter than "&quot;".
	`"`, "&#34;",
	// "&#39;" is shorter than "&apos;" and apos was not in HTML until HTML5.
	"'", "&#39;",
)

type FileSystem interface {
	ReadDir(core.Resource, bool) ([]core.Resource, error)
	FindVersion(core.Resource, uuid.UUID) (core.Version, error)
}

func Serve(w http.ResponseWriter, r *http.Request, f FileSystem, res core.Resource) {
	if res.Dir() {
		serveCollection(w, r, f, res)
	} else {
		ServeResourceVersion(w, r, f, res, res.LatestVersion().ID)
	}
}

func serveCollection(w http.ResponseWriter, r *http.Request, f FileSystem, file core.Resource) {
	if !strings.HasSuffix(r.URL.Path, "/") {
		http.Redirect(w, r, r.URL.String()+"/", http.StatusMovedPermanently)
		return
	}
	// if checkIfModifiedSince(r, file) == condFalse {
	// 	writeNotModified(w)
	// 	return
	// }
	w.Header().Set("Last-Modified", file.Modified().Format(http.TimeFormat))

	files, err := f.ReadDir(file, false)
	if err != nil {
		http.Error(w, "Error reading directory", http.StatusInternalServerError)
		return
	}
	// sort.Slice(files, func(i, j int) bool { return files[i].Name < files[j].Name })
	sort.Slice(files, func(i, j int) bool {
		a := files[i]
		b := files[j]
		if a.Dir() != b.Dir() {
			if a.Dir() {
				return true
			}
		}
		return strings.Compare(strings.ToLower(a.Name()), strings.ToLower((b.Name()))) <= 0
	})

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	fmt.Fprintln(w, "<html>")
	fmt.Fprintln(w, "<head>")
	fmt.Fprintf(w, "<title>%s | Phylum</title>\n", file.Name())
	fmt.Fprintln(w, "<style>td, th {padding: 4px 12px;}</style>")
	fmt.Fprintln(w, "</head>")
	fmt.Fprintln(w, "<body>")
	fmt.Fprintln(w, "<pre>")
	fmt.Fprintf(w, "<h2>Index of %s</h2>", file.Name())
	fmt.Fprintln(w, "<table>")
	fmt.Fprintln(w, "<thead><tr><th>Name</th><th>Size</th><th>Content-Type</th><th>SHA-256</th></tr></thead>")
	fmt.Fprintln(w, "<tbody>")
	for _, f := range files {
		name := f.Name()
		if f.Dir() {
			name += "/"
		}
		// name may contain '?' or '#', which must be escaped to remain
		// part of the URL path, and not indicate the start of a query
		// string or fragment.
		url := url.URL{Path: name}
		link := fmt.Sprintf("<a href=\"%s\">%s</a>", url.String(), htmlReplacer.Replace(name))

		if f.Dir() {
			fmt.Fprintf(w, "<tr><td>%s</td></tr>\n", link)
		} else {
			v := f.LatestVersion()
			fmt.Fprintf(w, "<tr><td>%s</td><td align=\"right\">%s</td><td>%s</td><td>%s</td></tr>\n", link, formatSize(int(v.Size)), v.MimeType, v.SHA256[0:12])
		}
	}
	fmt.Fprintln(w, "</tbody></table></pre>")
	fmt.Fprintln(w, "</body></html>")
}

func formatSize(size int) string {
	suffix := []string{"", "K", "M", "G", "T"}
	si := 0
	for ; size >= 1000 && si < len(suffix); si, size = si+1, size/1000 {
	}
	return fmt.Sprintf("%d%s", size, suffix[si])
}

func ServeResourceVersion(w http.ResponseWriter, r *http.Request, f FileSystem, res core.Resource, versionID uuid.UUID) {
	version, err := f.FindVersion(res, versionID)
	if err != nil {
		panic(err)
	}

	w.Header().Set("Etag", version.SHA256)
	w.Header().Set("Last-Modified", time.UnixMilli(int64(version.Created)).Format(http.TimeFormat))
	w.Header().Set("Content-Type", version.MimeType)

	done, rangeReq := checkPreconditions(w, r, version.VersionInfo)
	if done {
		return
	}

	code := http.StatusOK
	contentLength := int(version.Size)
	ranges, err := parseRange(rangeReq, contentLength)
	if err != nil {
		w.Header().Set("Content-Range", fmt.Sprintf("bytes */%d", contentLength))
		http.Error(w, err.Error(), http.StatusRequestedRangeNotSatisfiable)
		return
	}

	var reader io.ReadCloser
	if len(ranges) == 1 {
		// RFC 7233, Section 4.1:
		// "If a single part is being transferred, the server
		// generating the 206 response MUST generate a
		// Content-Range header field, describing what range
		// of the selected representation is enclosed, and a
		// payload consisting of the range.
		// ...
		// A server MUST NOT generate a multipart response to
		// a request for a single range, since a client that
		// does not request multiple parts might not support
		// multipart responses."
		ra := ranges[0]
		contentLength = ra.length
		reader, err = version.OpenRead(ra.start, ra.length)
		if err == nil {
			code = http.StatusPartialContent
			w.Header().Set("Content-Range", ra.contentRange(int(version.Size)))
		} else if errors.Is(err, storage.ErrRangeNotSupported) {
			err = nil
		}
	} else {
		reader, err = version.OpenRead(0, -1)
	}

	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Accept-Ranges", "bytes")
	w.Header().Set("Content-Length", strconv.Itoa(contentLength))
	w.WriteHeader(code)

	if r.Method != "HEAD" {
		io.CopyN(w, reader, int64(contentLength))
	}
}

// httpRange specifies the byte range to be sent to the client.
type httpRange struct {
	start, length int
}

func (r httpRange) contentRange(size int) string {
	return fmt.Sprintf("bytes %d-%d/%d", r.start, r.start+r.length-1, size)
}

// parseRange parses a Range header string as per RFC 7233.
// errNoOverlap is returned if none of the ranges overlap.
func parseRange(s string, size int) ([]httpRange, error) {
	if s == "" {
		return nil, nil // header not present
	}
	const b = "bytes="
	if !strings.HasPrefix(s, b) {
		return nil, errors.New("invalid range")
	}
	var ranges []httpRange
	noOverlap := false
	for _, ra := range strings.Split(s[len(b):], ",") {
		ra = textproto.TrimString(ra)
		if ra == "" {
			continue
		}
		start, end, ok := strings.Cut(ra, "-")
		if !ok {
			return nil, errors.New("invalid range")
		}
		start, end = textproto.TrimString(start), textproto.TrimString(end)
		var r httpRange
		if start == "" {
			// If no start is specified, end specifies the
			// range start relative to the end of the file,
			// and we are dealing with <suffix-length>
			// which has to be a non-negative integer as per
			// RFC 7233 Section 2.1 "Byte-Ranges".
			if end == "" || end[0] == '-' {
				return nil, errors.New("invalid range")
			}
			i, err := strconv.Atoi(end)
			if i < 0 || err != nil {
				return nil, errors.New("invalid range")
			}
			if i > size {
				i = size
			}
			r.start = size - i
			r.length = size - r.start
		} else {
			i, err := strconv.Atoi(start)
			if err != nil || i < 0 {
				return nil, errors.New("invalid range")
			}
			if i >= size {
				// If the range begins after the size of the content,
				// then it does not overlap.
				noOverlap = true
				continue
			}
			r.start = i
			if end == "" {
				// If no end is specified, range extends to end of the file.
				r.length = size - r.start
			} else {
				i, err := strconv.Atoi(end)
				if err != nil || r.start > i {
					return nil, errors.New("invalid range")
				}
				if i >= size {
					i = size - 1
				}
				r.length = i - r.start + 1
			}
		}
		ranges = append(ranges, r)
	}
	if noOverlap && len(ranges) == 0 {
		if size == 0 {
			// Some clients add a Range header to all requests to
			// limit the size of the response. If the file is empty,
			// ignore the range header
			return nil, nil
		}
		return nil, errors.New("invalid range: failed to overlap")
	}
	return ranges, nil
}

// checkPreconditions evaluates request preconditions and reports whether a precondition
// resulted in sending StatusNotModified or StatusPreconditionFailed.
func checkPreconditions(w http.ResponseWriter, r *http.Request, v core.VersionInfo) (done bool, rangeHeader string) {
	// This function carefully follows RFC 7232 section 6.
	ch := checkIfMatch(r, v)
	if ch == condNone {
		ch = checkIfUnmodifiedSince(r, v)
	}
	if ch == condFalse {
		w.WriteHeader(http.StatusPreconditionFailed)
		return true, ""
	}
	switch checkIfNoneMatch(r, v) {
	case condFalse:
		if r.Method == "GET" || r.Method == "HEAD" {
			writeNotModified(w)
			return true, ""
		} else {
			w.WriteHeader(http.StatusPreconditionFailed)
			return true, ""
		}
	case condNone:
		if checkIfModifiedSince(r, v) == condFalse {
			writeNotModified(w)
			return true, ""
		}
	}

	rangeHeader = r.Header.Get("Range")
	if rangeHeader != "" && checkIfRange(r, v) == condFalse {
		rangeHeader = ""
	}
	return false, rangeHeader
}

// scanETag determines if a syntactically valid ETag is present at s. If so,
// the ETag and remaining text after consuming ETag is returned. Otherwise,
// it returns "", "".
func scanETag(s string) (etag string, remain string) {
	s = textproto.TrimString(s)
	start := 0
	if strings.HasPrefix(s, "W/") {
		start = 2
	}
	if len(s[start:]) < 2 || s[start] != '"' {
		return "", ""
	}
	// ETag is either W/"text" or "text".
	// See RFC 7232 2.3.
	for i := start + 1; i < len(s); i++ {
		c := s[i]
		switch {
		// Character values allowed in ETags.
		case c == 0x21 || c >= 0x23 && c <= 0x7E || c >= 0x80:
		case c == '"':
			return s[:i+1], s[i+1:]
		default:
			return "", ""
		}
	}
	return "", ""
}

// etagStrongMatch reports whether a and b match using strong ETag comparison.
// Assumes a and b are valid ETags.
func etagStrongMatch(a, b string) bool {
	return a == b && a != "" && a[0] == '"'
}

// etagWeakMatch reports whether a and b match using weak ETag comparison.
// Assumes a and b are valid ETags.
func etagWeakMatch(a, b string) bool {
	return strings.TrimPrefix(a, "W/") == strings.TrimPrefix(b, "W/")
}

// condResult is the result of an HTTP request precondition check.
// See https://tools.ietf.org/html/rfc7232 section 3.
type condResult int

const (
	condNone condResult = iota
	condTrue
	condFalse
)

func checkIfMatch(r *http.Request, v core.VersionInfo) condResult {
	im := r.Header.Get("If-Match")
	if im == "" {
		return condNone
	}
	for {
		im = textproto.TrimString(im)
		if len(im) == 0 {
			break
		}
		if im[0] == ',' {
			im = im[1:]
			continue
		}
		if im[0] == '*' {
			return condTrue
		}
		etag, remain := scanETag(im)
		if etag == "" {
			break
		}
		if etagStrongMatch(etag, v.SHA256) {
			return condTrue
		}
		im = remain
	}

	return condFalse
}

func checkIfUnmodifiedSince(r *http.Request, v core.VersionInfo) condResult {
	ius := r.Header.Get("If-Unmodified-Since")
	if ius == "" {
		return condNone
	}
	t, err := http.ParseTime(ius)
	if err != nil {
		return condNone
	}

	// The Last-Modified header truncates sub-second precision so
	// the modtime needs to be truncated too.
	if v.Created < int(t.Unix()) {
		return condTrue
	}
	return condFalse
}

func checkIfNoneMatch(r *http.Request, v core.VersionInfo) condResult {
	inm := r.Header.Get("If-None-Match")
	if inm == "" {
		return condNone
	}
	buf := inm
	for {
		buf = textproto.TrimString(buf)
		if len(buf) == 0 {
			break
		}
		if buf[0] == ',' {
			buf = buf[1:]
			continue
		}
		if buf[0] == '*' {
			return condFalse
		}
		etag, remain := scanETag(buf)
		if etag == "" {
			break
		}
		if etagWeakMatch(etag, v.SHA256) {
			return condFalse
		}
		buf = remain
	}
	return condTrue
}

func checkIfModifiedSince(r *http.Request, v core.VersionInfo) condResult {
	if r.Method != "GET" && r.Method != "HEAD" {
		return condNone
	}
	ims := r.Header.Get("If-Modified-Since")
	if ims == "" {
		return condNone
	}
	t, err := http.ParseTime(ims)
	if err != nil {
		return condNone
	}
	// The Last-Modified header truncates sub-second precision so
	// the modtime needs to be truncated too.
	if v.Created <= int(t.Unix()) {
		return condFalse
	}
	return condTrue
}

func checkIfRange(r *http.Request, v core.VersionInfo) condResult {
	if r.Method != "GET" && r.Method != "HEAD" {
		return condNone
	}
	ir := r.Header.Get("If-Range")
	if ir == "" {
		return condNone
	}
	etag, _ := scanETag(ir)
	if etag != "" {
		if etagStrongMatch(etag, v.SHA256) {
			return condTrue
		} else {
			return condFalse
		}
	}
	t, err := http.ParseTime(ir)
	if err != nil {
		return condFalse
	}
	if t.Unix() == int64(v.Created) {
		return condTrue
	}
	return condFalse
}

func writeNotModified(w http.ResponseWriter) {
	// RFC 7232 section 4.1:
	// a sender SHOULD NOT generate representation metadata other than the
	// above listed fields unless said metadata exists for the purpose of
	// guiding cache updates (e.g., Last-Modified might be useful if the
	// response does not have an ETag field).
	h := w.Header()
	delete(h, "Content-Type")
	delete(h, "Content-Length")
	delete(h, "Content-Encoding")
	if h.Get("Etag") != "" {
		delete(h, "Last-Modified")
	}
	w.WriteHeader(http.StatusNotModified)
}
