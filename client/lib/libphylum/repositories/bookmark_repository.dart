import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_add.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_remove.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/bookmarks_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';

const keyLastBookmarkFetch = "lastBookmarksFetch";

class BookmarkRepository {
  final PhylumAccount account;

  BookmarkRepository({required this.account});

  Future<void> initialize({bool clearLastFetchTimestamp = false}) async {
    if (clearLastFetchTimestamp) {
      await account.persist(keyLastBookmarkFetch, null);
    }
    refresh();
  }

  Future<void> addBookmark({required Resource resource, String? name}) {
    return account.addAction(ResourceBookmarkAddAction(
      resourceId: resource.id,
      bookmarkName: name == null || name.trim().isEmpty ? resource.name : name,
      dir: resource.dir,
      createdMillis: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> removeBookmark({required Resource resource}) async {
    final bookmark =
        await (account.db.bookmarks.select()..where((b) => b.resourceId.equals(resource.id))).getSingleOrNull();
    if (bookmark == null) return;
    return account.addAction(ResourceBookmarkRemoveAction(
      resourceId: resource.id,
      bookmarkName: bookmark.name,
    ));
  }

  Future<ApiResult> refresh() async {
    return account.apiClient.sendRequest(
      BookmarksRequest(since: account.getPersisted(keyLastBookmarkFetch) as int?),
      (request, response) => parseJsonMapResponse(response, BookmarkListResponse.fromResponse),
    );
  }
}
