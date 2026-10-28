package serve

import (
	"embed"
	"fmt"
	"net/http"
	"net/url"
	"path"
	"slices"
	"strings"
	"text/template"
	"time"

	"codeberg.org/shroff/phylum/server/internal/core"
)

//go:embed listing.html
var baseFS embed.FS
var listing *template.Template

func init() {
	funcMap := template.FuncMap{
		"isNotLast": func(index, length int) bool { return index != length-1 },
		"parentPath": func(u string, length, index int) string {
			arr := make([]string, length-index)
			for i := range arr {
				arr[i] = ".."
			}
			arr[0] = u
			return path.Clean(path.Join(arr...))
			// return path.Join(a, b)
		},
	}
	var err error
	str, _ := baseFS.ReadFile("listing.html")
	listing, err = template.New("").Funcs(funcMap).Parse(string(str))
	if err != nil {
		panic(err)
	}
}

type ListingData struct {
	URL     string
	Title   string
	Path    []string
	Entries []ListingEntry
}

type ListingEntry struct {
	Folder       bool
	Name         string
	Link         string
	Size         string
	ContentType  string
	LastModified time.Time
	SHA256       string
}

func serveCollection(w http.ResponseWriter, r *http.Request, f FileSystem, file core.Resource) {
	if !strings.HasSuffix(r.URL.Path, "/") {
		http.Redirect(w, r, r.URL.String()+"/", http.StatusMovedPermanently)
		return
	}
	w.Header().Set("Last-Modified", file.Modified().Format(http.TimeFormat))

	files, err := f.ReadDir(file, false)
	if err != nil {
		http.Error(w, "Error reading directory", http.StatusInternalServerError)
		return
	}

	slices.SortFunc(files, func(a, b core.Resource) int {
		if a.Dir() != b.Dir() {
			if a.Dir() {
				return -1
			}
			return 1
		}
		return strings.Compare(strings.ToLower(a.Name()), strings.ToLower((b.Name())))
	})

	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	var path []string
	if ancestors, err := f.GetAncestors(file); err != nil {
		panic(err)
	} else {
		for _, e := range ancestors {
			path = append(path, htmlReplacer.Replace(e.Name))
		}
	}
	path = append(path, file.Name())
	data := ListingData{
		URL:     r.URL.EscapedPath(),
		Title:   htmlReplacer.Replace(file.Name()),
		Path:    path,
		Entries: make([]ListingEntry, len(files)),
	}
	for i, f := range files {
		name := f.Name()
		if f.Dir() {
			name += "/"
		}
		url := url.URL{Path: name}
		data.Entries[i] = ListingEntry{
			Folder:       f.Dir(),
			Name:         htmlReplacer.Replace(name),
			Link:         url.String(),
			LastModified: f.Modified(),
		}
		if !f.Dir() {
			v := f.LatestVersion()
			data.Entries[i].Size = formatSize(int(v.Size))
			data.Entries[i].ContentType = v.MimeType
			data.Entries[i].SHA256 = v.SHA256[0:12]
		}
	}
	listing.Execute(w, data)
}

func formatSize(size int) string {
	suffix := []string{"B", "K", "M", "G", "T"}
	si := 0
	for ; size >= 1000 && si < len(suffix); si, size = si+1, size/1000 {
	}
	return fmt.Sprintf("%d%s", size, suffix[si])
}
