package fs

import (
	"time"

	"github.com/google/uuid"
	"github.com/shroff/phylum/server/internal/core"
)

type ResourceMetadata struct {
	ID          uuid.UUID  `json:"id"`
	Parent      *uuid.UUID `json:"parent"`
	Name        string     `json:"name"`
	Dir         bool       `json:"dir"`
	Modified    time.Time  `json:"modified"`
	Deleted     *time.Time `json:"deleted"`
	ContentType string     `json:"ctype"`
	Size        int64      `json:"size"`
	Etag        string     `json:"etag"`
	Permissions string     `json:"permissions"`
}

type DiskUsageResponse struct {
	TotalSize int64 `json:"size"`
	Files     int64 `json:"files"`
	Dirs      int64 `json:"dirs"`
}

type ResourceDetailResponse struct {
	Metadata             core.Resource   `json:"metadata"`
	Children             []core.Resource `json:"children,omitempty"`
	InheritedPermissions string          `json:"inherited,omitempty"`
}

func DetailedResponseFromResource(fs core.FileSystem, r core.Resource) ResourceDetailResponse {
	response := ResourceDetailResponse{}
	response.Metadata = r
	if r.Dir {
		children, err := fs.ReadDir(r)
		if err != nil {
			panic(err)
		}
		response.Children = make([]core.Resource, len(children))
		for i, c := range children {
			response.Children[i] = c
		}
	}
	response.InheritedPermissions = r.InheritedPermissions
	return response
}
