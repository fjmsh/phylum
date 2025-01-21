import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

const _remoteResourcesBoxName = 'remote_resources';
const _remoteBookmarksBoxName = 'remote_bookmarks';

class PhylumChangeTracker extends LocalChangeTracker<PhylumAccount> {
  PhylumChangeTracker({required super.account});

  @override
  Future<void> initialize(Iterable<PhylumAction> actions) async {
    await registerTracker(await ResourceChangeTracker.create(account));
    await registerTracker(await BookmarkChangeTracker.create(account));
    super.initialize(actions);
  }
}

class ResourceChangeTracker extends TypedChangeTracker<PhylumAccount, Resource> {
  late final PhylumAccount account;
  late final LazyBox<Resource?> _remoteDataBox;

  @override
  String get typeName => 'resource';

  ResourceChangeTracker._(this.account, this._remoteDataBox, super._remoteData);

  static Future<ResourceChangeTracker> create(PhylumAccount account) async {
    if (!Hive.isAdapterRegistered(const ResourceAdapter().typeId)) {
      Hive.registerAdapter(const ResourceAdapter());
    }
    final box = await account.openBox<Resource>(_remoteResourcesBoxName);
    final remoteData = Map<String, Resource?>.fromIterable(box.keys, value: (key) => box.get(key));
    await box.close();
    return ResourceChangeTracker._(account, await account.openLazyBox(_remoteResourcesBoxName), remoteData);
  }

  @override
  Future<void> persistRemoteData(Map<String, Resource?> remoteData) {
    return _remoteDataBox.putAll(remoteData);
  }

  @override
  Future<void> discardRemoteData(Iterable<String> objectIds) {
    return _remoteDataBox.deleteAll(objectIds);
  }

  @override
  Future<Resource?> load(String objectId) async {
    final data = await account.db.getResource(objectId);
    return data;
  }

  @override
  Future<void> save(String objectId, Resource data) {
    return account.db.resources.insertOne(data, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<void> delete(String objectId) async {
    await account.db.resources.deleteWhere((r) => r.id.equals(objectId));
  }
}

class BookmarkChangeTracker extends TypedChangeTracker<PhylumAccount, Bookmark> {
  late final PhylumAccount account;
  late final LazyBox<Bookmark?> _remoteDataBox;

  @override
  String get typeName => 'bookmark';

  BookmarkChangeTracker._(this.account, this._remoteDataBox, super._remoteData);

  static Future<BookmarkChangeTracker> create(PhylumAccount account) async {
    if (!Hive.isAdapterRegistered(const BookmarkAdapter().typeId)) {
      Hive.registerAdapter(const BookmarkAdapter());
    }
    final box = await account.openBox<Bookmark>(_remoteBookmarksBoxName);
    final remoteData = Map<String, Bookmark?>.fromIterable(box.keys, value: (key) => box.get(key));
    await box.close();
    return BookmarkChangeTracker._(account, await account.openLazyBox(_remoteBookmarksBoxName), remoteData);
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
    return (account.db.bookmarks.select()..where((o) => o.resourceId.equals(objectId))).getSingleOrNull();
  }

  @override
  Future<void> save(String objectId, Bookmark data) {
    return account.db.bookmarks.insertOne(data, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<void> delete(String objectId) async {
    await account.db.bookmarks.deleteWhere((r) => r.resourceId.equals(objectId));
  }
}

class ResourceAdapter implements TypeAdapter<Resource?> {
  const ResourceAdapter();

  @override
  int get typeId => 1;

  @override
  Resource? read(BinaryReader reader) {
    reader.readByte();
    final data = reader.readString();
    return data.isEmpty ? null : Resource.fromJson(json.decode(data));
  }

  @override
  void write(BinaryWriter writer, Resource? obj) {
    writer.writeByte(0); // Version marker, in case we need to change something in the future
    writer.writeString(obj?.toJsonString() ?? '');
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
