part of 'parsers.dart';

const keyLastBookmarkFetch = "lastBookmarksFetch";

class BookmarkListResponse extends PhylumApiSuccessResponse {
  final Iterable<Bookmark> bookmarks;
  final int until;

  @override
  Iterable<(Type, String)> get updatedObjects => bookmarks.map((b) => (Bookmark, b.resourceId));

  BookmarkListResponse({required this.bookmarks, required this.until});

  factory BookmarkListResponse.fromResponse(Map<String, dynamic> data) {
    final bookmarks =
        (data["bookmarks"] as List).cast<Map>().map((u) => parseBookmarkObject(u.cast<String, dynamic>()));
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

class BookmarkResponse extends PhylumApiSuccessResponse {
  final Bookmark bookmark;

  @override
  Iterable<(Type, String)> get updatedObjects => [(Bookmark, bookmark.resourceId)];

  BookmarkResponse({required this.bookmark});

  factory BookmarkResponse.fromResponse(Map<String, dynamic> data) {
    final bookmark = parseBookmarkObject((data as Map).cast<String, dynamic>());
    return BookmarkResponse(bookmark: bookmark);
  }

  @override
  Future process(PhylumAccount account) async {
    return account.db.bookmarks.insertOnConflictUpdate(bookmark);
  }
}

Bookmark parseBookmarkObject(Map<String, dynamic> data) {
  return Bookmark(
    resourceId: data['resource_id'],
    name: data['name'],
    created: data['created'],
    deleted: data['deleted'],
  );
}
