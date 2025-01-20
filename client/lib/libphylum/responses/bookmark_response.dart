part of 'responses.dart';

class BookmarkResponse extends PhylumApiSuccessResponse {
  final Bookmark bookmark;

  @override
  Iterable<(Type, String)> get updatedObjects => [(Bookmark, bookmark.resourceId)];

  BookmarkResponse({required this.bookmark});

  factory BookmarkResponse.fromResponse(Map<String, dynamic> data) {
    final bookmark = parseBookmark((data as Map).cast<String, dynamic>());
    return BookmarkResponse(bookmark: bookmark);
  }

  @override
  Future process(PhylumAccount account) async {
    return account.db.bookmarks.insertOnConflictUpdate(bookmark);
  }
}
