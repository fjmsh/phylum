package responses

import "codeberg.org/shroff/phylum/server/internal/core"

func FullResourceFromFS(f core.FileSystem, r core.Resource) ResourceFull {
	response := ResourceFull{
		Resource: ResourceFromFS(r),
	}
	ancestors, err := f.GetAncestors(r)
	if err != nil {
		panic(err)
	}
	response.Ancestors = make([]Ancestor, len(ancestors))

	for i, a := range ancestors {
		response.Ancestors[i] = Ancestor{
			ID:             a.ID,
			Name:           a.Name,
			UserPermission: a.UserPermission,
		}
	}
	if r.Dir() {
		children, err := f.ReadDir(r, false)
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

func ResourceFromFS(r core.Resource) Resource {
	var deleted int64 = 0
	if r.Deleted().Valid {
		deleted = r.Deleted().Time.UnixMilli()
	}
	return Resource{
		ID:                   r.ID(),
		Parent:               r.VisibleParentID(),
		Name:                 r.Name(),
		Dir:                  r.Dir(),
		Created:              r.Created().UnixMilli(),
		Modified:             r.Modified().UnixMilli(),
		Deleted:              deleted,
		InheritedPermissions: r.InheritedPermissions(),
		Grants:               r.Grants(),
		Versions:             r.Versions(),
		Links:                r.Links(),
	}
}

func PublinkFromFS(p core.Publink) Publink {
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
