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

var applicationTextTypes = map[string]bool{
	"json":  true,
	"yaml":  true,
	"toml":  true,
	"x-sh":  true,
	"x-sql": true,
	"xml":   true,
}
var applicationImageTypes = map[string]bool{
	"pdf":        true,
	"postscript": true,
}

var applicationDocumentTypes = map[string]bool{
	"msword":                              true,
	"vnd.ms-excel":                        true,
	"vnd.ms-powerpoint":                   true,
	"vnd.oasis.opendocument.presentation": true,
	"vnd.oasis.opendocument.spreadsheet":  true,
	"vnd.oasis.opendocument.text":         true,
	"vnd.openxmlformats-officedocument.presentationml.presentation": true,
	"vnd.openxmlformats-officedocument.spreadsheetml.sheet":         true,
	"vnd.openxmlformats-officedocument.wordprocessingml.document":   true,
}
