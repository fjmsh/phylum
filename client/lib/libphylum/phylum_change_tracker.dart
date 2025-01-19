import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';

class PhylumChangeTracker extends LocalChangeTracker<PhylumAccount> {
  PhylumChangeTracker({required super.account});

  @override
  Future<void> initialize() async {
    super.initialize();
    await registerTracker(await ResourceChangeTracker.create(account));
  }

  Future<int> create(String id, String parent, String name, bool dir, DateTime timestamp) {
    return account.db.resources.insertOne(
      ResourcesCompanion.insert(
        id: id,
        name: name,
        parent: Value(parent),
        dir: dir,
        created: Value(timestamp),
        modified: Value(timestamp),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> update(String id, Insertable<Resource> update) {
    return (account.db.resources.update()..where((f) => f.id.equals(id))).write(update);
  }
}

class ResourceChangeTracker extends TypedChangeTracker<PhylumAccount, Resource> {
  late final PhylumAccount account;
  late final LazyBox<Resource?> _serverDataBox;

  @override
  String get typeName => 'resource';

  ResourceChangeTracker._(this.account, this._serverDataBox, super._remoteData);

  static Future<ResourceChangeTracker> create(PhylumAccount account) async {
    if (!Hive.isAdapterRegistered(const ResourceAdapter().typeId)) {
      Hive.registerAdapter(const ResourceAdapter());
    }
    final box = await account.openBox<Resource>('server_data');
    final remoteData = Map<String, Resource?>.fromIterable(box.keys, value: (key) => box.get(key));
    await box.close();
    return ResourceChangeTracker._(account, await account.openLazyBox('server_data'), remoteData);
  }

  @override
  Future<void> persistRemoteData(String objectId, Resource? data) {
    return _serverDataBox.put(objectId, data);
  }

  @override
  Future<void> discardRemoteData(String objectId) {
    return _serverDataBox.delete(objectId);
  }

  @override
  Future<Resource?> load(String objectId) {
    return account.db.getResource(objectId);
  }

  @override
  Future<void> update(String objectId, Resource data) async {
    await (account.db.resources.update()..where((f) => f.id.equals(objectId))).write(data);
  }

  @override
  Future<void> delete(String objectId) async {
    await account.db.resources.deleteWhere((r) => r.id.equals(objectId));
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
