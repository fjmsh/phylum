package mail

import (
	"embed"
	"html/template"
	"path"
	"path/filepath"
)

//go:embed emails/contents/**
var contentsFS embed.FS

//go:embed emails/base/**
var baseFS embed.FS
var emails = make(map[string]Email)

type Email struct {
	Subject string
	Plain   *template.Template
	HTML    *template.Template
}

func init() {
	baseHTML, err := baseFS.ReadFile(filepath.Join("emails", "base", "base.html"))
	if err != nil {
		panic(err)
	}
	baseText, err := baseFS.ReadFile(filepath.Join("emails", "base", "base.txt"))
	if err != nil {
		panic(err)
	}

	dirName := filepath.Join("emails", "contents")
	dir, err := contentsFS.ReadDir(dirName)
	if err != nil {
		panic(err)
	}
	for _, e := range dir {
		name := e.Name()
		subject, err := contentsFS.ReadFile(path.Join(dirName, name, "subject"))
		if err != nil {
			panic(err)
		}

		textBody, err := contentsFS.ReadFile(path.Join(dirName, name, "body.txt"))
		if err != nil {
			panic(err)
		}
		textTemplate, err := template.New("").Parse(string(textBody))
		if err != nil {
			panic(err)
		}
		textTemplate, err = textTemplate.Parse(string(baseText))
		if err != nil {
			panic(err)
		}

		htmlBody, err := contentsFS.ReadFile(path.Join(dirName, name, "body.html"))
		if err != nil {
			panic(err)
		}
		htmlTemplate, err := template.New("").Parse(string(htmlBody))
		if err != nil {
			panic(err)
		}
		htmlTemplate, err = htmlTemplate.Parse(string(baseHTML))
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
