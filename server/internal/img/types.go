package img

var imageTypes = map[string]bool{
	"bmp":     true,
	"gif":     true,
	"heic":    true,
	"heif":    true,
	"jpeg":    true,
	"png":     true,
	"svg+xml": true,
	"webp":    true,
	"x-icon":  true,
}

var applicationTypes = map[string]func(string) (Res, error){
	"json":  processText,
	"yaml":  processText,
	"toml":  processText,
	"x-sh":  processText,
	"x-sql": processText,
	"xml":   processText,

	"pdf":        processApplicationImage,
	"postscript": processApplicationImage,

	"msword":                              processDocument,
	"vnd.ms-excel":                        processDocument,
	"vnd.ms-powerpoint":                   processDocument,
	"vnd.oasis.opendocument.presentation": processDocument,
	"vnd.oasis.opendocument.spreadsheet":  processDocument,
	"vnd.oasis.opendocument.text":         processDocument,
	"vnd.openxmlformats-officedocument.presentationml.presentation": processDocument,
	"vnd.openxmlformats-officedocument.spreadsheetml.sheet":         processDocument,
	"vnd.openxmlformats-officedocument.wordprocessingml.document":   processDocument,

	"epub+zip": processEpub,
}
