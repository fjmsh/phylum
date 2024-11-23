package webdav

import (
	"net/http"
	"net/url"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core/errors"
)

func (h *Handler) handleCopyMove(_ http.ResponseWriter, r *http.Request) (status int, err error) {
	hdr := r.Header.Get("Destination")
	if hdr == "" {
		return http.StatusBadRequest, errInvalidDestination
	}
	u, err := url.Parse(hdr)
	if err != nil {
		return http.StatusBadRequest, errInvalidDestination
	}
	if u.Host != "" && u.Host != r.Host {
		return http.StatusBadGateway, errInvalidDestination
	}

	src, status, err := h.stripPrefix(r.URL.Path)
	if err != nil {
		return status, err
	}

	dst, status, err := h.stripPrefix(u.Path)
	if err != nil {
		return status, err
	}

	if dst == "" {
		return http.StatusBadGateway, errInvalidDestination
	}
	if dst == src {
		return http.StatusForbidden, errDestinationEqualsSource
	}

	depth := infiniteDepth
	if hdr := r.Header.Get("Depth"); hdr != "" {
		depth = parseDepth(hdr)
	}

	if r.Method == "COPY" {
		// Section 7.5.1 says that a COPY only needs to lock the destination,
		// not both destination and source. Strictly speaking, this is racy,
		// even though a COPY doesn't modify the source, if a concurrent
		// operation modifies the source. However, the litmus test explicitly
		// checks that COPYing a locked-by-another source is OK.
		release, status, err := h.confirmLocks(r, "", dst)
		if err != nil {
			return status, err
		}
		defer release()

		// Section 9.8.3 says that "The COPY method on a collection without a Depth
		// header must act as if a Depth header with value "infinity" was included".
		if depth != 0 && depth != infiniteDepth {
			// Section 9.8.3 says that "A client may submit a Depth header on a
			// COPY on a collection with a value of "0" or "infinity"."
			return http.StatusBadRequest, errInvalidDepth
		}
		return copyFiles(h.FileSystem, src, dst, r.Header.Get("Overwrite") != "F", depth)
	}

	release, status, err := h.confirmLocks(r, src, dst)
	if err != nil {
		return status, err
	}
	defer release()

	// Section 9.9.2 says that "The MOVE method on a collection must act as if
	// a "Depth: infinity" header was used on it. A client must not submit a
	// Depth header on a MOVE on a collection with any value but "infinity"."
	if depth != infiniteDepth {
		return http.StatusBadRequest, errInvalidDepth
	}
	return moveFiles(h.FileSystem, src, dst, r.Header.Get("Overwrite") == "T")
}

// moveFiles moves files and/or directories from src to dst.
//
// See section 9.9.4 for when various HTTP status codes apply.
func moveFiles(fs FileSystem, srcPath, dstPath string, overwrite bool) (status int, err error) {
	if src, err := fs.ResourceByPath(srcPath); err != nil {
		if e, ok := err.(*errors.Error); ok {
			return e.Status, e
		}
		return http.StatusInternalServerError, err
	} else {
		if _, deleted, err := src.Move(dstPath, overwrite); err != nil {
			if e, ok := err.(*errors.Error); ok {
				return e.Status, e
			}
			return http.StatusForbidden, err
		} else {
			status = http.StatusCreated
			if deleted {
				status = http.StatusNoContent
			}
			return status, nil
		}
	}
}

// copyFiles copies files and/or directories from src to dst.
//
// See section 9.8.5 for when various HTTP status codes apply.
func copyFiles(fs FileSystem, srcPath, dstPath string, overwrite bool, depth int) (status int, err error) {
	if src, err := fs.ResourceByPath(srcPath); err != nil {
		if e, ok := err.(*errors.Error); ok {
			return e.Status, e
		}
		return http.StatusInternalServerError, err
	} else {
		id, _ := uuid.NewV7()
		if _, deleted, err := src.Copy(dstPath, id, depth != 0, overwrite); err != nil {
			if e, ok := err.(*errors.Error); ok {
				return e.Status, e
			}
			return http.StatusForbidden, err
		} else {
			status = http.StatusCreated
			if deleted {
				status = http.StatusNoContent
			}
			return status, nil
		}
	}
}
