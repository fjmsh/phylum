package mail

import (
	"embed"
	"html/template"
	"path"
)

//go:embed emails/**
var emailFS embed.FS
var emails = make(map[string]Email)

type Email struct {
	Subject string
	Plain   *template.Template
	HTML    *template.Template
}

func init() {
	dir, err := emailFS.ReadDir("emails")
	if err != nil {
		panic(err)
	}
	for _, e := range dir {
		name := e.Name()
		subject, err := emailFS.ReadFile(path.Join("emails", name, "subject"))
		if err != nil {
			panic(err)
		}

		textBody, err := emailFS.ReadFile(path.Join("emails", name, "body.txt"))
		if err != nil {
			panic(err)
		}
		textTemplate, err := template.New("").Parse(string(textBody))
		if err != nil {
			panic(err)
		}

		htmlBody, err := emailFS.ReadFile(path.Join("emails", name, "body.html"))
		if err != nil {
			panic(err)
		}
		htmlTemplate, err := template.New("").Parse(string(htmlBody))
		if err != nil {
			panic(err)
		}

		emails[name] = Email{
			Subject: string(subject),
			Plain:   textTemplate,
			HTML:    htmlTemplate,
		}

	}
}
