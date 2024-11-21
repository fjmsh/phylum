import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/bookmarks_request.dart';

const keyLastBookmarkFetch = "lastBookmarksFetch";

class BookmarkRepository {
  final PhylumAccount account;

  BookmarkRepository({required this.account});

  Future<void> initialize(bool cleared) async {
    if (cleared) {
      await account.persist(keyLastBookmarkFetch, null);
    }
    refresh();
  }

  Selectable<ListBookmarksResult> list() {
    return account.db.listBookmarks();
  }

  Future<int> insertOrReplace(Bookmark bookmark) {
    return account.db.bookmarks.insertOne(bookmark, mode: InsertMode.insertOrReplace);
  }

  Future<int> update(String id, Insertable<Bookmark> update) {
    return (account.db.bookmarks.update()..where((b) => b.resourceId.equals(id))).write(update);
  }

  Future<int> delete(String id) {
    return account.db.bookmarks.deleteWhere((f) => f.resourceId.equals(id));
  }

  Selectable<int> bookmarksCount(Iterable<String> ids) {
    return account.db.bookmarks.count(where: (b) => b.resourceId.isIn(ids) & b.deleted.equals(false));
  }

  Future<ApiResult> refresh() async {
    return account.apiClient.sendRequest(
      BookmarksRequest(since: account.getPersisted(keyLastBookmarkFetch) as int?),
      callback: (request, response) async {
        if (response is PhylumApiSuccessResponse) {
          await processBookmarksResponse(response.data);
        }
      },
    );
  }

  Future processBookmarksResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final bookmarks = (data["bookmarks"] as List).cast<Map>().map((u) => parseBookmarkObject(u.cast<String, dynamic>()));
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.bookmarks, bookmarks);
    });
    account.persist(keyLastBookmarkFetch, data["until"]);
  }

  Future processSingleBookmarkResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final bookmark = parseBookmarkObject((data as Map).cast<String, dynamic>());
    return db.bookmarks.insertOnConflictUpdate(bookmark);
  }

  Bookmark parseBookmarkObject(Map<String, dynamic> data) {
    return Bookmark(
      resourceId: data['resource_id'],
      name: data['name'],
      created: data['created'],
      deleted: data['deleted'],
    );
  }
}
