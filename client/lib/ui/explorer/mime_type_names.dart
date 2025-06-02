String mimeTypeName(String mimeType) {
  final index = mimeType.indexOf(';');
  if (index > 0) {
    mimeType = mimeType.substring(0, index);
  }
  final name = _fullTypeNames[mimeType];
  if (name != null) return name;

  final parts = mimeType.split('/');
  return _categoryNames[parts[0]] ?? 'Unknown';
}

const _categoryNames = <String, String>{
  'application': 'Other',
  'text': 'Text',
  'audio': 'Audio',
  'video': 'Video',
  'image': 'Image',
};

const _fullTypeNames = <String, String>{
  // Application
  'application/epub+zip': 'EPUB E-Book',
  'application/json': 'JSON',
  'application/manifest+json': 'Web Manifest',
  'application/msword': 'Word Document (Legacy)',
  'application/octet-stream': 'Binary Data',
  'application/pdf': 'PDF Document',
  'application/postscript': 'PostScript Document',
  'application/vnd.android.package-archive': 'Android Application Package',
  'application/vnd.ms-excel': 'Excel Spreadsheet (Legacy)',
  'application/vnd.ms-powerpoint': 'PowerPoint Presentation (Legacy)',
  'application/vnd.oasis.opendocument.presentation': 'OpenOffice Presentation',
  'application/vnd.oasis.opendocument.spreadsheet': 'OpenOffice Spreadsheet',
  'application/vnd.oasis.opendocument.text': 'OpenOffice Text Document',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation': 'PowerPoint Presentation',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet': 'Excel Spreadsheet',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document': 'Word Document',
  'application/x-bzip': 'BZip Archive',
  'application/x-bzip2': 'BZip Archive',
  'application/x-latex': 'LaTeX Document',
  'application/x-msdownload': 'Windows Application',
  'application/x-rar-compressed': 'RAR Archive',
  'application/x-tex': 'TeX Document',
  'application/x-sh': 'Shell Script',
  'application/x-sql': 'SQL Script',
  'application/xml': 'XML',
  'application/zip': 'Zip Archive',

  // Audio
  'audio/aac': 'AAC Audio',
  'audio/mpeg': 'MPEG Audio',
  'audio/mp4': 'MP4 Audio',
  'audio/ogg': 'OGG Audio',
  'audio/webm': 'WEBM Audio',
  'audio/x-flac': 'FLAC Audio',
  'audio/x-wav': 'WAV Audio',

  // Image
  'image/bmp': 'Bitmap Image',
  'image/gif': 'GIF Image',
  'image/heic': 'HEIC Image',
  'image/heif': 'HEIF Image',
  'image/jpeg': 'JPEG Image',
  'image/png': 'PNG Image',
  'image/svg+xml': 'SVG Image',
  'image/vnd.adobe.photoshop': 'Photoshop Image',
  'image/webp': 'WebP Image',
  'image/x-icon': 'Favicon Image',

  // Text
  'text/css': 'CSS Source Code',
  'text/csv': 'Comma-Separated Values',
  'text/html': 'HTML Source Code',
  'text/ics': 'Calendar Invite',
  'text/javascript': 'JS Source Code',
  'text/markdown': 'Markdown',
  'text/plain': 'Plain Text',
  'text/vnd.dvb.subtitle': 'Subtitles',
  'text/x-c': 'C/C++ Source Code',
  'text/x-dart': 'Dart Source Code',
  'text/x-vcard': 'vCard',

  // Video
  'video/mp4': 'MP4 Video',
  'video/mpeg': 'MPEG Video',
  'video/quicktime': 'MOV Video',
  'video/webm': 'WEBM Video',
  'video/x-matroska': 'MKV Video',
  'video/x-msvideo': 'AVI Video',
  'video/x-ms-wmv': 'WMV Video',
};
