import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive_ce/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

const _remoteBoxName = 'remote_publinks';

class PublinkRepository extends Repository<PhylumAccount, Publink> {
  late final PhylumAccount _account;
  late final LazyBox<Publink?> _remoteDataBox;

  PublinkRepository();

  @override
  Future<Map<String, Publink?>> initializeAndRestoreRemoteData(
    PhylumAccount account,
  ) async {
    if (!Hive.isAdapterRegistered(const PublinkAdapter().typeId)) {
      Hive.registerAdapter(const PublinkAdapter());
    }

    final box = await account.openBox<Publink>(_remoteBoxName);
    final remoteData = Map<String, Publink?>.fromIterable(
      box.keys,
      value: (key) => box.get(key),
    );
    await box.close();
    _account = account;

    _remoteDataBox = await _account.openLazyBox(_remoteBoxName);
    return remoteData;
  }

  @override
  Future<void> persistRemoteData(Map<String, Publink?> remoteData) {
    return _remoteDataBox.putAll(remoteData);
  }

  @override
  Future<void> discardRemoteData(Iterable<String> objectIds) {
    return _remoteDataBox.deleteAll(objectIds);
  }

  @override
  Future<Publink?> load(String objectId) {
    return (_account.db.publinks.select()..where((o) => o.id.equals(objectId)))
        .getSingleOrNull();
  }

  @override
  Future<void> save(String objectId, Publink data) {
    return _account.db.publinks.insertOne(
      data,
      mode: InsertMode.insertOrReplace,
    );
  }

  @override
  Future<void> delete(String objectId) {
    return _account.db.publinks.deleteWhere((o) => o.id.equals(objectId));
  }
}

class PublinkAdapter implements TypeAdapter<Publink?> {
  const PublinkAdapter();

  @override
  int get typeId => 4;

  @override
  Publink? read(BinaryReader reader) {
    reader.readByte();
    final data = reader.readString();
    return data.isEmpty ? null : Publink.fromJson(json.decode(data));
  }

  @override
  void write(BinaryWriter writer, Publink? obj) {
    writer.writeByte(
      0,
    ); // Version marker, in case we need to change something in the future
    writer.writeString(obj?.toJsonString() ?? '');
  }
}
