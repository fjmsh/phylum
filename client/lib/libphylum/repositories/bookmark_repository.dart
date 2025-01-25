import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_add.dart';
import 'package:phylum/libphylum/actions/action_resource_bookmark_remove.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/bookmarks_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';

const keyLastBookmarkFetch = "lastBookmarksFetch";
const _remoteBookmarksBoxName = 'remote_bookmarks';

class BookmarkRepository extends Repository<PhylumAccount, Bookmark> {
  late final PhylumAccount _account;
  late final LazyBox<Bookmark?> _remoteDataBox;

  BookmarkRepository();

  @override
  Future<Map<String, Bookmark?>> initializeAndRestoreRemoteData(PhylumAccount account) async {
    if (!Hive.isAdapterRegistered(const BookmarkAdapter().typeId)) {
      Hive.registerAdapter(const BookmarkAdapter());
    }
    final box = await _account.openBox<Bookmark>(_remoteBookmarksBoxName);
    final remoteData = Map<String, Bookmark?>.fromIterable(box.keys, value: (key) => box.get(key));
    await box.close();
    _account = account;
    _remoteDataBox = await _account.openLazyBox(_remoteBookmarksBoxName);
    return remoteData;
  }

  Future<void> initialize({bool clearLastFetchTimestamp = false}) async {
    if (clearLastFetchTimestamp) {
      await _account.persist(keyLastBookmarkFetch, null);
    }
    refresh();
  }

  Future<void> addBookmark({required Resource resource, String? name}) {
    return _account.addAction(ResourceBookmarkAddAction(
      resourceId: resource.id,
      bookmarkName: name == null || name.trim().isEmpty ? resource.name : name,
      dir: resource.dir,
      createdMillis: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> removeBookmark({required Resource resource}) async {
    final bookmark =
        await (_account.db.bookmarks.select()..where((b) => b.resourceId.equals(resource.id))).getSingleOrNull();
    if (bookmark == null) return;
    return _account.addAction(ResourceBookmarkRemoveAction(
      resourceId: resource.id,
      bookmarkName: bookmark.name,
    ));
  }

  Future<ApiResult> refresh() async {
    return _account.apiClient.sendRequest(
      BookmarksRequest(since: _account.getPersisted(keyLastBookmarkFetch) as int?),
      (request, response) => parseJsonMapResponse(response, BookmarkListResponse.fromResponse),
    );
  }

  @override
  Future<void> persistRemoteData(Map<String, Bookmark?> remoteData) {
    return _remoteDataBox.putAll(remoteData);
  }

  @override
  Future<void> discardRemoteData(Iterable<String> objectIds) {
    return _remoteDataBox.deleteAll(objectIds);
  }

  @override
  Future<Bookmark?> load(String objectId) {
    return (_account.db.bookmarks.select()..where((o) => o.resourceId.equals(objectId))).getSingleOrNull();
  }

  @override
  Future<void> save(String objectId, Bookmark data) {
    return _account.db.bookmarks.insertOne(data, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<void> delete(String objectId) async {
    await _account.db.bookmarks.deleteWhere((r) => r.resourceId.equals(objectId));
  }
}

class BookmarkAdapter implements TypeAdapter<Bookmark?> {
  const BookmarkAdapter();

  @override
  int get typeId => 2;

  @override
  Bookmark? read(BinaryReader reader) {
    reader.readByte();
    final data = reader.readString();
    return data.isEmpty ? null : Bookmark.fromJson(json.decode(data));
  }

  @override
  void write(BinaryWriter writer, Bookmark? obj) {
    writer.writeByte(0); // Version marker, in case we need to change something in the future
    writer.writeString(obj?.toJsonString() ?? '');
  }
}
