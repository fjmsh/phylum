package responses

import "github.com/shroff/phylum/server/internal/core/fs"

func FullResourceFromFS(r fs.Resource) ResourceFull {
	response := ResourceFull{
		Resource: ResourceFromFS(r),
	}
	ancestors, err := r.GetAncestors()
	if err != nil {
		panic(err)
	}
	response.Ancestors = make([]Ancestor, len(ancestors))

	for i, a := range ancestors {
		response.Ancestors[i] = Ancestor{
			ID:          a.ID,
			Name:        a.Name,
			Permissions: string(a.Permissions),
		}
	}
	if r.Dir() {
		children, err := r.ReadDir(false)
		if err != nil {
			panic(err)
		}
		response.Children = make([]Resource, len(children))
		for i, c := range children {
			response.Children[i] = ResourceFromFS(c)
		}
	}
	return response
}

func ResourceFromFS(r fs.Resource) Resource {
	var deleted int64 = 0
	if r.Deleted().Valid {
		deleted = r.Deleted().Time.UnixMilli()
	}
	return Resource{
		ID:                   r.ID(),
		Name:                 r.Name(),
		Dir:                  r.Dir(),
		Created:              r.Created().UnixMilli(),
		Modified:             r.Modified().UnixMilli(),
		Deleted:              deleted,
		ContentLength:        r.ContentLength(),
		ContentType:          r.ContentType(),
		ContentSHA256:        r.ContentSHA256(),
		InheritedPermissions: string(r.InheritedPermissions()),
		Grants:               string(r.Grants()),
		Links:                r.Links(),
	}
}

func PublinkFromFS(p fs.Publink) Publink {
	return Publink{
		ID:          p.ID,
		Created:     p.Created,
		Root:        p.Root,
		Accessed:    p.Accessed,
		AccessLimit: p.AccessLimit,
		Protected:   p.PasswordHash != "",
		Expires:     p.Expires,
	}
}
