// Copyright 2015 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package webdav

import (
	"bytes"
	"encoding/xml"
	"net/http"
	"strconv"

	"github.com/shroff/phylum/server/internal/api/serve"
)

// Proppatch describes a property update instruction as defined in RFC 4918.
// See http://www.webdav.org/specs/rfc4918.html#METHOD_PROPPATCH
type Proppatch struct {
	// Remove specifies whether this patch removes properties. If it does not
	// remove them, it sets them.
	Remove bool
	// Props contains the properties to be set or removed.
	Props []Property
}

// Propstat describes a XML propstat element as defined in RFC 4918.
// See http://www.webdav.org/specs/rfc4918.html#ELEMENT_propstat
type Propstat struct {
	// Props contains the properties for which Status applies.
	Props []Property

	// Status defines the HTTP status code of the properties in Prop.
	// Allowed values include, but are not limited to the WebDAV status
	// code extensions for HTTP/1.1.
	// http://www.webdav.org/specs/rfc4918.html#status.code.extensions.to.http11
	Status int

	// XMLError contains the XML representation of the optional error element.
	// XML content within this field must not rely on any predefined
	// namespace declarations or prefixes. If empty, the XML error element
	// is omitted.
	XMLError string

	// ResponseDescription contains the contents of the optional
	// responsedescription field. If empty, the XML element is omitted.
	ResponseDescription string
}

// makePropstats returns a slice containing those of x and y whose Props slice
// is non-empty. If both are empty, it returns a slice containing an otherwise
// zero Propstat whose HTTP status code is 200 OK.
func makePropstats(x, y Propstat) []Propstat {
	pstats := make([]Propstat, 0, 2)
	if len(x.Props) != 0 {
		pstats = append(pstats, x)
	}
	if len(y.Props) != 0 {
		pstats = append(pstats, y)
	}
	if len(pstats) == 0 {
		pstats = append(pstats, Propstat{
			Status: http.StatusOK,
		})
	}
	return pstats
}

// liveProps contains all supported, protected DAV: properties.
var liveProps = map[xml.Name]struct {
	// findFn implements the propfind function of this property. If nil,
	// it indicates a hidden property.
	findFn func(serve.Resource) string
	// dir is true if the property applies to directories.
	dir bool
}{
	{Space: "DAV:", Local: "resourcetype"}: {
		findFn: findResourceType,
		dir:    true,
	},
	{Space: "DAV:", Local: "displayname"}: {
		findFn: findDisplayName,
		dir:    true,
	},
	{Space: "DAV:", Local: "getcontentlength"}: {
		findFn: findContentLength,
		dir:    false,
	},
	{Space: "DAV:", Local: "getlastmodified"}: {
		findFn: findLastModified,
		// http://webdav.org/specs/rfc4918.html#PROPERTY_getlastmodified
		// suggests that getlastmodified should only apply to GETable
		// resources, and this package does not support GET on directories.
		//
		// Nonetheless, some WebDAV clients expect child directories to be
		// sortable by getlastmodified date, so this value is true, not false.
		// See golang.org/issue/15334.
		dir: true,
	},
	{Space: "DAV:", Local: "creationdate"}: {
		findFn: findCreationDate,
		dir:    true,
	},
	{Space: "DAV:", Local: "getcontentlanguage"}: {
		findFn: nil,
		dir:    false,
	},
	{Space: "DAV:", Local: "getcontenttype"}: {
		findFn: findContentType,
		dir:    false,
	},
	{Space: "DAV:", Local: "getetag"}: {
		findFn: findETag,
		// findETag implements ETag as the concatenated hex values of a file's
		// modification time and size. This is not a reliable synchronization
		// mechanism for directories, so we do not advertise getetag for DAV
		// collections.
		dir: false,
	},

	// TODO: The lockdiscovery property requires LockSystem to list the
	// active locks on a resource.
	{Space: "DAV:", Local: "lockdiscovery"}: {},
	{Space: "DAV:", Local: "supportedlock"}: {
		findFn: findSupportedLock,
		dir:    true,
	},
}

// TODO(nigeltao) merge props and allprop?

// props returns the status of the properties named pnames for resource name.
//
// Each Propstat has a unique status and each property name will only be part
// of one Propstat element.
func props(fs FileSystem, ls LockSystem, fi serve.Resource, pnames []xml.Name) ([]Propstat, error) {
	pstatOK := Propstat{Status: http.StatusOK}
	pstatNotFound := Propstat{Status: http.StatusNotFound}
	for _, pn := range pnames {
		// Otherwise, it must either be a live property or we don't know it.
		if prop := liveProps[pn]; prop.findFn != nil && (prop.dir || !fi.FSDir()) {
			innerXML := prop.findFn(fi)
			pstatOK.Props = append(pstatOK.Props, Property{
				XMLName:  pn,
				InnerXML: []byte(innerXML),
			})
		} else {
			pstatNotFound.Props = append(pstatNotFound.Props, Property{
				XMLName: pn,
			})
		}
	}
	return makePropstats(pstatOK, pstatNotFound), nil
}

// propnames returns the property names defined for resource name.
func propnames(fs FileSystem, ls LockSystem, fi serve.Resource) ([]xml.Name, error) {
	pnames := make([]xml.Name, 0, len(liveProps))
	for pn, prop := range liveProps {
		if prop.findFn != nil && (prop.dir || !fi.FSDir()) {
			pnames = append(pnames, pn)
		}
	}
	return pnames, nil
}

// allprop returns the properties defined for resource name and the properties
// named in include.
//
// Note that RFC 4918 defines 'allprop' to return the DAV: properties defined
// within the RFC plus dead properties. Other live properties should only be
// returned if they are named in 'include'.
//
// See http://www.webdav.org/specs/rfc4918.html#METHOD_PROPFIND
func allprop(fs FileSystem, ls LockSystem, fi serve.Resource, include []xml.Name) ([]Propstat, error) {
	pnames, err := propnames(fs, ls, fi)
	if err != nil {
		return nil, err
	}
	// Add names from include if they are not already covered in pnames.
	nameset := make(map[xml.Name]bool)
	for _, pn := range pnames {
		nameset[pn] = true
	}
	for _, pn := range include {
		if !nameset[pn] {
			pnames = append(pnames, pn)
		}
	}
	return props(fs, ls, fi, pnames)
}

// patch patches the properties of resource name. The return values are
// constrained in the same manner as DeadPropsHolder.Patch.
func patch(fs FileSystem, ls LockSystem, name string, patches []Proppatch) ([]Propstat, error) {
	conflict := false
loop:
	for _, patch := range patches {
		for _, p := range patch.Props {
			if _, ok := liveProps[p.XMLName]; ok {
				conflict = true
				break loop
			}
		}
	}
	if conflict {
		pstatForbidden := Propstat{
			Status:   http.StatusForbidden,
			XMLError: `<D:cannot-modify-protected-property xmlns:D="DAV:"/>`,
		}
		pstatFailedDep := Propstat{
			Status: http.StatusFailedDependency,
		}
		for _, patch := range patches {
			for _, p := range patch.Props {
				if _, ok := liveProps[p.XMLName]; ok {
					pstatForbidden.Props = append(pstatForbidden.Props, Property{XMLName: p.XMLName})
				} else {
					pstatFailedDep.Props = append(pstatFailedDep.Props, Property{XMLName: p.XMLName})
				}
			}
		}
		return makePropstats(pstatForbidden, pstatFailedDep), nil
	}

	// All patches are forbidden.
	pstat := Propstat{Status: http.StatusForbidden}
	for _, patch := range patches {
		for _, p := range patch.Props {
			pstat.Props = append(pstat.Props, Property{XMLName: p.XMLName})
		}
	}
	return []Propstat{pstat}, nil
}

func escapeXML(s string) string {
	for i := 0; i < len(s); i++ {
		// As an optimization, if s contains only ASCII letters, digits or a
		// few special characters, the escaped value is s itself and we don't
		// need to allocate a buffer and convert between string and []byte.
		switch c := s[i]; {
		case c == ' ' || c == '_' ||
			('+' <= c && c <= '9') || // Digits as well as + , - . and /
			('A' <= c && c <= 'Z') ||
			('a' <= c && c <= 'z'):
			continue
		}
		// Otherwise, go through the full escaping process.
		var buf bytes.Buffer
		xml.EscapeText(&buf, []byte(s))
		return buf.String()
	}
	return s
}

func findResourceType(fi serve.Resource) string {
	if fi.FSDir() {
		return `<D:collection xmlns:D="DAV:"/>`
	}
	return ""
}

func findDisplayName(fi serve.Resource) string {
	return escapeXML(fi.FSName())
}

func findContentLength(fi serve.Resource) string {
	return strconv.FormatInt(fi.FSContentSize(), 10)
}

func findCreationDate(fi serve.Resource) string {
	return fi.FSCreated().UTC().Format(http.TimeFormat)
}

func findLastModified(fi serve.Resource) string {
	return fi.FSModified().UTC().Format(http.TimeFormat)
}

func findContentType(fi serve.Resource) string {
	return fi.FSContentType()
}

func findETag(fi serve.Resource) string {
	return fi.FSContentSHA256()
}

func findSupportedLock(fi serve.Resource) string {
	return `` +
		`<D:lockentry xmlns:D="DAV:">` +
		`<D:lockscope><D:exclusive/></D:lockscope>` +
		`<D:locktype><D:write/></D:locktype>` +
		`</D:lockentry>`
}
