part of 'responses.dart';

class BookmarkResponse extends PhylumApiSuccessResponse {
  final Bookmark bookmark;

  BookmarkResponse({required this.bookmark});

  factory BookmarkResponse.fromResponse(Map<String, dynamic> data) {
    final bookmark = parseBookmark((data as Map).cast<String, dynamic>());
    return BookmarkResponse(bookmark: bookmark);
  }

  @override
  Future<void> process(PhylumAccount account) async {
    await account.db.bookmarks.insertOne(bookmark, mode: InsertMode.insertOrReplace);
    await account.datastore.get<Bookmark>().replaceRemoteData(bookmark.resourceId, bookmark);
  }
}
