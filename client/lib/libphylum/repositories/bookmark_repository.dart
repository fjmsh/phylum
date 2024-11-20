import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/bookmarks_request.dart';

const keyLastBookmarkFetch = "lastBookmarksFetch";

class BookmarkRepository {
  final PhylumAccount account;
  List<Bookmark> _bookmarks = const [];
  List<Bookmark> get bookmarks => _bookmarks;

  BookmarkRepository({required this.account}) {
    account.db.bookmarks.select().get().then(
          (bookmarks) => _bookmarks = List.unmodifiable(bookmarks),
        );
  }

  Future<ApiResult> refresh() async {
    return account.apiClient.sendRequest(
      BookmarksRequest(since: account.getPersisted(keyLastBookmarkFetch) as int?),
      callback: (request, response) async {
        if (response is PhylumApiSuccessResponse) {
          await parseBookmarksResponse(response.data);
        }
      },
    );
  }

  Future parseBookmarksResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final bookmarks = (data["bookmarks"] as List).cast<Map>().map((u) => parseBookmarkObject(u.cast<String, dynamic>()));
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.bookmarks, bookmarks);
    });
    account.persist(keyLastBookmarkFetch, data["until"]);
    _bookmarks = List.unmodifiable(bookmarks);
  }

  Bookmark parseBookmarkObject(Map<String, dynamic> data) {
    return Bookmark(
      resourceId: data['resource_id'],
      name: data['name'],
      deleted: data['deleted'],
    );
  }
}
