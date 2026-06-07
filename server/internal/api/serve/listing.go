package serve

import (
	"embed"
	"fmt"
	"net/http"
	"net/url"
	"slices"
	"sort"
	"strings"
	"text/template"

	"codeberg.org/shroff/phylum/server/internal/core"
)

//go:embed listing.html
var baseFS embed.FS
var listing *template.Template

func init() {
	funcMap := template.FuncMap{
		"isNotLast": func(index, length int) bool { return index != length-1 },
	}
	var err error
	str, _ := baseFS.ReadFile("listing.html")
	listing, err = template.New("").Funcs(funcMap).Parse(string(str))
	if err != nil {
		panic(err)
	}
}

type ListingData struct {
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
	LastModified string
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
	ancestors, err := f.GetAncestors(file)
	if err != nil {
		panic(err)
	}
	var path []string
	var found bool
	for _, e := range slices.Backward(ancestors) {
		found = found || f.IsRoot(e.ID)
		if found {
			path = append(path, e.Name)
		}
	}
	path = append(path, file.Name())
	data := ListingData{
		Title:   file.Name(),
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
			Folder: f.Dir(),
			Name:   htmlReplacer.Replace(name),
			Link:   url.String(),
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
