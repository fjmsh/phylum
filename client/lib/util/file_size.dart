typedef FileSize = int;

extension FileSizeString on FileSize {
  String getHumanString() {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var sz = this;
    for (var i = 0; i < suffixes.length; i++) {
      if (sz < 1000) {
        return '$sz ${suffixes[i]}';
      }
      sz ~/= 1024;
    }
    return '$sz T';
  }
}
