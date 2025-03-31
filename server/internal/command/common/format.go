package common

import (
	"encoding/json"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/core/fs"
)

func formatRow(id string, dir bool, size int, sha256, name, permissions string, deleted bool) string {
	sizeStr := "    -"
	if dir {
		sha256 = "-       "
	} else {
		sizeStr = FormatSize(size)
	}
	if sha256 == "" {
		sha256 = "xxxxxxxx"
	}
	delStr := " "
	if deleted {
		delStr = "*"
	}
	return fmt.Sprintf("%s %s %s %s%-24s %s", id, sizeStr, sha256[0:8], delStr, name, permissions)
}

func FormatResourceSummary(r fs.Resource, name string, deleted pgtype.Timestamp) string {
	if name == "" {
		name = r.Name()
	}
	if r.Dir() {
		name += "/"
	}
	return formatRow(r.ID().String(), r.Dir(), int(r.ContentLength()), r.ContentSHA256(), name, formatGrantsJson(r.Grants()), deleted != r.Deleted())
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
