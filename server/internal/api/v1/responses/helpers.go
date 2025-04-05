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
			ParentID:    a.ParentID,
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
	return Resource{
		ID:            r.ID(),
		Name:          r.Name(),
		ParentID:      r.ParentID(),
		Dir:           r.Dir(),
		Created:       r.Created(),
		Modified:      r.Modified(),
		ContentLength: r.ContentLength(),
		ContentType:   r.ContentType(),
		ContentSHA256: r.ContentSHA256(),
		Permissions:   string(r.Permissions()),
		Grants:        string(r.Grants()),
		Links:         string(r.Links()),
	}
}
