part of 'responses.dart';

const keyLastBookmarkFetch = "lastBookmarksFetch";

class BookmarkListResponse extends PhylumApiSuccessResponse {
  final Iterable<Bookmark> bookmarks;
  final int until;

  BookmarkListResponse({required this.bookmarks, required this.until});

  factory BookmarkListResponse.fromResponse(Map<String, dynamic> data) {
    final bookmarks = (data["bookmarks"] as List).cast<Map>().map((u) => parseBookmark(u.cast<String, dynamic>()));
    return BookmarkListResponse(bookmarks: bookmarks, until: data['until'] as int);
  }

  @override
  Future process(PhylumAccount account) async {
    await account.db.batch((batch) {
      batch.insertAll(account.db.bookmarks, bookmarks, mode: InsertMode.replace);
    });
    for (final b in bookmarks) {
      await account.datastore.get<Bookmark>().replaceRemoteData(b.resourceId, b);
    }
  }
}
