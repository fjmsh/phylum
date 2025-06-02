import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive_ce/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

const _remoteBoxName = 'remote_resource_versions';

class ResourceVersionRepository extends Repository<PhylumAccount, ResourceVersion> {
  late final PhylumAccount _account;
  late final LazyBox<ResourceVersion?> _remoteDataBox;

  ResourceVersionRepository();

  @override
  Future<Map<String, ResourceVersion?>> initializeAndRestoreRemoteData(PhylumAccount account) async {
    if (!Hive.isAdapterRegistered(const ResourceVersionAdapter().typeId)) {
      Hive.registerAdapter(const ResourceVersionAdapter());
    }

    final box = await account.openBox<ResourceVersion>(_remoteBoxName);
    final remoteData = Map<String, ResourceVersion?>.fromIterable(box.keys, value: (key) => box.get(key));
    await box.close();
    _account = account;

    _remoteDataBox = await _account.openLazyBox(_remoteBoxName);
    return remoteData;
  }

  @override
  Future<void> persistRemoteData(Map<String, ResourceVersion?> remoteData) {
    return _remoteDataBox.putAll(remoteData);
  }

  @override
  Future<void> discardRemoteData(Iterable<String> objectIds) {
    return _remoteDataBox.deleteAll(objectIds);
  }

  @override
  Future<ResourceVersion?> load(String objectId) {
    return (_account.db.resourceVersions.select()..where((o) => o.id.equals(objectId))).getSingleOrNull();
  }

  @override
  Future<void> save(String objectId, ResourceVersion data) {
    return _account.db.resourceVersions.insertOne(data, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<void> delete(String objectId) {
    return _account.db.publinks.deleteWhere((o) => o.id.equals(objectId));
  }
}

class ResourceVersionAdapter implements TypeAdapter<ResourceVersion?> {
  const ResourceVersionAdapter();

  @override
  int get typeId => 5;

  @override
  ResourceVersion? read(BinaryReader reader) {
    reader.readByte();
    final data = reader.readString();
    return data.isEmpty ? null : ResourceVersion.fromJson(json.decode(data));
  }

  @override
  void write(BinaryWriter writer, ResourceVersion? obj) {
    writer.writeByte(0); // Version marker, in case we need to change something in the future
    writer.writeString(obj?.toJsonString() ?? '');
  }
}
