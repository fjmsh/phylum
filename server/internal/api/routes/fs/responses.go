package fs

type DiskUsageResponse struct {
	TotalSize int64 `json:"size"`
	Files     int64 `json:"files"`
	Dirs      int64 `json:"dirs"`
}
