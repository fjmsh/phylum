package common

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"strings"

	"codeberg.org/shroff/phylum/server/internal/core"
	"github.com/jackc/pgx/v5/pgtype"
)

func FormatResourceSummary(r core.Resource, name string, deleted pgtype.Timestamp) string {
	if name == "" {
		name = r.Name()
	}
	if r.Dir() {
		name += "/"
	}
	v := r.LatestVersion()
	sha256 := ""
	sizeStr := "    -"
	versions := "-"
	if r.Dir() {
		sha256 = "--      "
	} else {
		sizeStr = FormatSize(int(v.Size))
		if v.SHA256 == "" {
			sha256 = "xxxxxxxx"
		} else {
			sha256 = v.SHA256[0:8]
		}
		versionCount := parseVersions(r.Versions())
		versions = strconv.Itoa(versionCount)
		if versionCount > 9 {
			versions = "+"
		}
	}

	delStr := " "
	if deleted != r.Deleted() {
		delStr = "*"
	}
	return fmt.Sprintf("%s %d %s %s %s %s%-24s %s", r.ID().String(), len(parseLinks(r.Links())), versions, sizeStr, sha256, delStr, name, FormatGrantsJson(r.Grants()))
}

func FormatSize(size int) string {
	suffix := []string{"B", "K", "M", "G", "T"}
	si := 0
	for ; size >= 1000 && si < len(suffix); si, size = si+1, size/1000 {
	}
	return fmt.Sprintf("%4d%s", size, suffix[si])
}

func FormatPermissionsJson(j []byte) string {
	p := make(map[string]core.Permission)
	json.Unmarshal(j, &p)
	if len(p) == 0 {
		return ""
	}
	perm := make([]string, 0, len(p))
	for k, v := range p {
		email, err := userEmail(k)
		if err != nil {
			email = "unknown user (" + k + ")"
		}
		perm = append(perm, email+": "+formatPermission(v))
	}
	return "[" + strings.Join(perm, ", ") + "]"
}

func FormatGrantsJson(j []byte) string {
	g := make(map[string]grant)
	json.Unmarshal(j, &g)
	if len(g) == 0 {
		return ""
	}
	perm := make([]string, 0, len(g))
	for k, v := range g {
		email, err := userEmail(k)
		if err != nil {
			email = "unknown user (" + k + ")"
		}
		perm = append(perm, email+": "+formatPermission(v.Permission))
	}
	return "[" + strings.Join(perm, ", ") + "]"
}

type grant struct {
	Permission core.Permission `json:"p"`
	Timestamp  int             `json:"t"`
}

func userEmail(s string) (string, error) {
	id, err := strconv.Atoi(s)
	if err != nil {
		return "", err
	}
	return core.UserManagerFromContext(context.Background()).UserEmailByID(id)

}

func parseLinks(j []byte) []string {
	l := make([]map[string]interface{}, 0)
	json.Unmarshal(j, &l)

	links := make([]string, 0, len(l))
	for _, v := range l {
		links = append(links, v["id"].(string))
	}
	return links
}

func parseVersions(j []byte) int {
	v := make([]map[string]interface{}, 0)
	json.Unmarshal(j, &v)
	return len(v)
}

func formatPermission(p core.Permission) string {
	if p == core.PermissionSU {
		return "su"
	}
	str := ""
	if p&core.PermissionRead != 0 {
		p -= core.PermissionRead
		str += "r"
	}
	if p&core.PermissionWrite != 0 {
		p -= core.PermissionWrite
		str += "w"
	}
	if p&core.PermissionShare != 0 {
		p -= core.PermissionShare
		str += "s"
	}
	if p != 0 {
		str += fmt.Sprintf("u(%d)", p)
	}
	return str
}
