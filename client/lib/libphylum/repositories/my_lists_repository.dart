import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/libphylum/requests/bookmarks_request.dart';
import 'package:phylum/libphylum/requests/shared_resources_request.dart';

const keyLastBookmarkFetch = "lastBookmarksFetch";

class MyListsRepository {
  final PhylumAccount account;

  MyListsRepository({required this.account});

  Future<void> initialize({bool clearLastFetchTimestamp = false}) async {
    if (clearLastFetchTimestamp) {
      await account.persist(keyLastBookmarkFetch, null);
    }
    refreshBookmarks();
  }

  Stream<List<Resource>> watchRecents() {
    return account.db.selectRecents().watch();
  }

  Future<void> markResourceAccessed(String resourceId) {
    return account.db.recents.insertOnConflictUpdate(Recent(resourceId: resourceId, accessed: DateTime.now()));
  }

  Stream<List<Resource>> watchShared() {
    return account.db.selectShared().watch();
  }

  Future<ApiResult> refreshShared() async {
    return account.apiClient.sendRequest(SharedResourcesRequest(), callback: (request, response) async {
      if (response is PhylumApiSuccessResponse) {
        await processSharedResourcesResponse(response.data);
      }
    });
  }

  Stream<List<SelectBookmarksResult>> watchBookmarks() {
    return account.db.selectBookmarks().watch();
  }

  Selectable<int> countBookmarks(Iterable<String> ids) {
    return account.db.bookmarks.count(where: (b) => b.resourceId.isIn(ids) & b.deleted.equals(false));
  }

  Future<ApiResult> refreshBookmarks() async {
    return account.apiClient.sendRequest(
      BookmarksRequest(since: account.getPersisted(keyLastBookmarkFetch) as int?),
      (request, response) => parseJsonMapResponse(response, BookmarkListResponse.fromResponse),
    );
  }

  Future processSharedResourcesResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final resources =
        (data["shared"] as List).cast<Map>().map((u) => parsePartialResourceObject(u.cast<String, dynamic>()));
    final shared = resources.indexed.map((r) => SharedCompanion.insert(resourceId: r.$2.id.value, seq: r.$1));
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.resources, resources);
      batch.deleteAll(db.shared);
      batch.insertAll(db.shared, shared);
    });
    account.persist(keyLastBookmarkFetch, data["until"]);
  }
}
