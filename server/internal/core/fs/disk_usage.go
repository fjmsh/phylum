package fs

type DiskUsageInfo struct {
	TotalSize int64
	Entities  int64
	Files     int64
	Dirs      int64
}

func (f filesystem) DiskUsage(r Resource) (DiskUsageInfo, error) {
	if info, err := f.db.DiskUsage(f.ctx, r.ID); err != nil {
		return DiskUsageInfo{}, err
	} else {
		return DiskUsageInfo{
			TotalSize: info.Size,
			Entities:  info.Entities,
			Files:     info.Files,
			Dirs:      info.Dirs,
		}, nil
	}
}
