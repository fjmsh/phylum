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
	Deleted     *time.Time `json:"deleted,omitempty"`
	ContentType string     `json:"ctype,omitEmpty"`
	Size        int64      `json:"size"`
	Etag        string     `json:"etag"`
	Permissions string     `json:"permissions,omitempty"`
}

type DiskUsageResponse struct {
	TotalSize int64 `json:"size"`
	Files     int64 `json:"files"`
	Dirs      int64 `json:"dirs"`
}

type ResourceDetailResponse struct {
	Metadata             ResourceMetadata   `json:"metadata"`
	Children             []ResourceMetadata `json:"children,omitempty"`
	InheritedPermissions string             `json:"inherited,omitempty"`
}

func DetailedResponseFromResource(fs core.FileSystem, r core.Resource) ResourceDetailResponse {
	response := ResourceDetailResponse{}
	response.Metadata = ResponseFromResource(r)
	if r.IsDir() {
		children, err := fs.ReadDir(r)
		if err != nil {
			panic(err)
		}
		response.Children = make([]ResourceMetadata, len(children))
		for i, c := range children {
			response.Children[i] = ResponseFromResource(c)
		}
	}
	response.InheritedPermissions = r.InheritedPermissions()
	return response
}

func ResponseFromResource(r core.Resource) ResourceMetadata {
	return ResourceMetadata{
		ID:          r.ID(),
		Parent:      r.ParentID(),
		Name:        r.Name(),
		Dir:         r.IsDir(),
		Modified:    r.ModTime(),
		Deleted:     r.DelTime(),
		Size:        r.Size(),
		Etag:        r.ETag(),
		ContentType: r.ContentType(),
		Permissions: r.Permissions(),
	}
}
