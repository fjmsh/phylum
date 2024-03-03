package pgfs

import (
	"context"
	"encoding/base64"
	"hash"
	"io"
	"io/fs"
	"os"
	"strings"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgtype"
	"github.com/shroff/phylum/server/internal/phylumsql"

	webdav "github.com/emersion/go-webdav"
)

type Pgfs struct {
	q      phylumsql.Queries
	cs     ContentStore
	prefix string
}

func New(q phylumsql.Queries, cs ContentStore, prefix string) Pgfs {
	return Pgfs{q: q, cs: cs, prefix: prefix}
}

func (p Pgfs) Open(ctx context.Context, name string) (io.ReadCloser, error) {
	resource, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	return p.cs.Open(resource.ID)
}
func (p Pgfs) Stat(ctx context.Context, name string) (*webdav.FileInfo, error) {
	resource, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	val := &webdav.FileInfo{
		Path:     string(p.prefix + resource.Path),
		Size:     int64(resource.Size.Int32),
		ModTime:  resource.Modified.Time,
		IsDir:    resource.Dir,
		MIMEType: resource.Name,
		ETag:     resource.Etag.String,
	}
	return val, nil
}
func (p Pgfs) ReadDir(ctx context.Context, name string, recursive bool) ([]webdav.FileInfo, error) {
	dir, err := p.resourceByPath(ctx, name)
	if err != nil {
		return nil, err
	}
	if !dir.Dir {
		return nil, fs.ErrInvalid
	}
	children, err := p.q.ReadDir(ctx, phylumsql.ReadDirParams{ID: dir.ID, Recursive: recursive})
	if err != nil {
		return nil, err
	}

	result := make([]webdav.FileInfo, len(children))
	prefix := p.prefix + dir.Path
	for i, c := range children {
		result[i] = webdav.FileInfo{
			Path:     string(prefix + c.Path),
			Size:     int64(c.Size.Int32),
			ModTime:  c.Modified.Time,
			IsDir:    c.Dir,
			MIMEType: c.Name,
			ETag:     c.Etag.String,
		}
	}
	return result, nil
}
func (p Pgfs) Create(ctx context.Context, name string) (io.WriteCloser, error) {
	resource, _ := p.resourceByPath(ctx, name)
	if resource != nil {
		return p.cs.Create(resource.ID, func(h hash.Hash, err error) {
			if err != nil {
				etag := base64.StdEncoding.EncodeToString(h.Sum(nil))
				_, err = p.q.UpdateResourceContents(ctx, phylumsql.UpdateResourceContentsParams{
					Size: pgtype.Int4{Int32: int32(h.Size()), Valid: true},
					Etag: pgtype.Text{String: string(etag), Valid: true},
				})
			}
			if err != nil {
				p.cs.Delete(resource.ID)
			}
		})
	}
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := p.resourceByPath(ctx, parentPath)
	if err != nil {
		return nil, fs.ErrNotExist
	}
	fileName := name[index+1:]
	id := uuid.New()

	return p.cs.Create(id, func(h hash.Hash, err error) {
		etag := base64.StdEncoding.EncodeToString(h.Sum(nil))
		if err != nil {
			_, err = p.q.CreateFile(
				ctx,
				phylumsql.CreateFileParams{
					ID:     id,
					Parent: &parent.ID,
					Name:   fileName,
					Size:   pgtype.Int4{Int32: int32(h.Size()), Valid: true},
					Etag:   pgtype.Text{String: string(etag), Valid: true},
				})
		}
		if err != nil {
			p.cs.Delete(id)
		}
	})
}

func (p Pgfs) RemoveAll(ctx context.Context, name string) error {
	resource, _ := p.resourceByPath(ctx, name)
	if resource == nil {
		return fs.ErrNotExist
	}
	return p.q.DeleteRecursive(ctx, resource.ID)
}

func (p Pgfs) Mkdir(ctx context.Context, name string) error {
	resource, _ := p.resourceByPath(ctx, name)
	if resource != nil {
		return fs.ErrExist
	}
	index := strings.LastIndex(name, "/")
	parentPath := name[0:index]
	parent, err := p.resourceByPath(ctx, parentPath)
	if err != nil {
		return fs.ErrNotExist
	}
	dirName := name[index+1:]
	_, err = p.q.CreateDirectory(ctx, phylumsql.CreateDirectoryParams{ID: uuid.New(), Parent: &parent.ID, Name: dirName})
	return err
}
func (p Pgfs) Copy(ctx context.Context, name, dest string, options *webdav.CopyOptions) (created bool, err error) {
	// TODO: Implement
	return false, nil
}
func (p Pgfs) Move(ctx context.Context, name, dest string, options *webdav.MoveOptions) (created bool, err error) {
	// TODO: Implement
	return false, nil
}

func (p Pgfs) resourceByPath(ctx context.Context, name string) (*phylumsql.ResourceByPathRow, error) {
	path := strings.TrimPrefix(name, p.prefix+"/")
	segments := strings.Split(strings.TrimRight(path, "/"), "/")
	if len(segments) == 0 {
		return nil, os.ErrInvalid
	}

	root, err := p.q.FindRoot(ctx, segments[0])
	if err != nil {
		return nil, os.ErrNotExist
	}

	//TODO: Permissions checks
	res, err := p.q.ResourceByPath(ctx, phylumsql.ResourceByPathParams{Search: segments, Root: root.ID})
	if err != nil {
		return nil, os.ErrNotExist
	}

	return &res, nil
}
