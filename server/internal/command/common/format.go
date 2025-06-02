package common

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func FormatResourceSummary(r fs.Resource, name string, deleted pgtype.Timestamp) string {
	if name == "" {
		name = r.Name()
	}
	if r.Dir() {
		name += "/"
	}
	v, _ := r.LatestVersion()
	sha256 := v.SHA256
	sizeStr := "    -"
	if r.Dir() {
		sha256 = "-       "
	} else {
		sizeStr = FormatSize(int(v.Size))
	}
	if sha256 == "" {
		sha256 = "xxxxxxxx"
	}
	delStr := " "
	if deleted != r.Deleted() {
		delStr = "*"
	}
	return fmt.Sprintf("%s %s %s %s%-24s %s %s", r.ID().String(), sizeStr, sha256[0:8], delStr, name, formatGrantsJson(r.Grants()), r.Links())
}

func FormatSize(size int) string {
	suffix := []string{"B", "K", "M", "G", "T"}
	si := 0
	for ; size >= 1000 && si < len(suffix); si, size = si+1, size/1000 {
	}
	return fmt.Sprintf("%4d%s", size, suffix[si])
}

func formatGrantsJson(j []byte) string {
	p := make(map[string]interface{})
	json.Unmarshal(j, &p)
	if len(p) == 0 {
		return ""
	}
	perm := make([]string, 0, len(p))
	for k, v := range p {
		perm = append(perm, k+": "+FormatPermission(int32((v.(map[string]interface{})["p"]).(float64))))
	}
	return "[" + strings.Join(perm, ", ") + "]"
}

func FormatPermission(p fs.Permission) string {
	if p == fs.PermissionSU {
		return "su"
	}
	str := ""
	if p&fs.PermissionRead != 0 {
		p -= fs.PermissionRead
		str += "r"
	}
	if p&fs.PermissionWrite != 0 {
		p -= fs.PermissionWrite
		str += "w"
	}
	if p&fs.PermissionShare != 0 {
		p -= fs.PermissionShare
		str += "s"
	}
	if p != 0 {
		str += fmt.Sprintf("u(%d)", p)
	}
	return str
}
