package common

import (
	"encoding/json"
	"fmt"
	"math"
	"strconv"

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

	size := ""
	sha256 := ""
	versions := ""
	if r.Dir() {
		size = "    -"
		sha256 = "--      "
		versions = "-"
	} else {
		v := r.LatestVersion()
		size = FormatSize(int(v.Size))
		if v.SHA256 == "" {
			sha256 = "xxxxxxxx"
		} else {
			sha256 = v.SHA256[0:8]
		}
		versionCount := countJSONList(r.Versions())
		versions = strconv.Itoa(versionCount)
		if versionCount > 9 {
			versions = "+"
		}
	}

	delStr := " "
	if deleted != r.Deleted() {
		delStr = "*"
	}
	return fmt.Sprintf("%s %d %d %s %5s %s %s%-24s", r.ID().String(), countJSONMap(r.Grants()), countJSONList(r.Links()), versions, size, sha256, delStr, name)
}

func FormatSize(size int) string {
	suffix := []string{"B", "K", "M", "G", "T"}
	sz := float64(size)
	si := 0
	for ; sz >= 1000 && si < len(suffix); si, sz = si+1, sz/1024 {
	}
	if sz >= 10 || si == 0 {
		return strconv.Itoa(int(math.Ceil(sz))) + suffix[si]
		// return fmt.Sprintf("%d%s", int(math.Ceil(sz)), suffix[si])
	} else {
		return fmt.Sprintf("%1.1f%s", sz, suffix[si])
	}
}

// String formatForDisplay() {
//     const suffixes = ['B', 'K', 'M', 'G'];
//     var sz = toDouble();
//     for (var i = 0; i < suffixes.length; i++) {
//       if (sz < 1000) {
//         return '${i == 0 ? sz.toInt() : _formatSize(sz)}${suffixes[i]}';
//       }
//       sz /= 1024;
//     }
//     return '${_formatSize(sz)}T';
//   }

//   String _formatSize(double size) {
//     return size >= 10 ? '${size.toInt()}' : decimalPattern.format(size);
//   }

func countJSONMap(j []byte) int {
	g := make(map[string]interface{})
	json.Unmarshal(j, &g)
	return len(g)
}

func countJSONList(j []byte) int {
	l := make([]map[string]interface{}, 0)
	json.Unmarshal(j, &l)
	return len(l)
}
