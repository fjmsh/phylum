part of 'responses.dart';

const keyLastBookmarkFetch = "lastBookmarksFetch";

class BookmarkListResponse extends PhylumApiSuccessResponse {
  final Iterable<Bookmark> bookmarks;
  final int until;

  @override
  Iterable<(Type, String)> get updatedObjects => bookmarks.map((b) => (Bookmark, b.resourceId));

  BookmarkListResponse({required this.bookmarks, required this.until});

  factory BookmarkListResponse.fromResponse(Map<String, dynamic> data) {
    final bookmarks = (data["bookmarks"] as List).cast<Map>().map((u) => parseBookmark(u.cast<String, dynamic>()));
    return BookmarkListResponse(bookmarks: bookmarks, until: data['until'] as int);
  }

  @override
  Future process(PhylumAccount account) async {
    await account.db.batch((batch) {
      batch.insertAllOnConflictUpdate(account.db.bookmarks, bookmarks);
    });
    await account.persist(keyLastBookmarkFetch, until);
  }
}
