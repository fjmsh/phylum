package fs

type DiskUsageInfo struct {
	TotalSize int64
	Entities  int64
	Files     int64
	Dirs      int64
}

func (r Resource) DiskUsage() (DiskUsageInfo, error) {
	if info, err := r.f.db.DiskUsage(r.f.ctx, r.ID()); err != nil {
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
