import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';

class LocalChangeTracker {
  final PhylumAccount account;
  late final Box<Resource?> _serverDataBox;
  // Map<String, Resource?> _pending = {};

  LocalChangeTracker({required this.account});

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(const ResourceAdapter().typeId)) {
      Hive.registerAdapter(const ResourceAdapter());
    }
    _serverDataBox = await account.openBox('server_data');
  }

  Future<int> create(String id, String parent, String name, bool dir, DateTime timestamp) {
    // This will create a key with null value, which is exactly what we want
    _retainOriginal(id);
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
    _retainOriginal(id);
    return (account.db.resources.update()..where((f) => f.id.equals(id))).write(update);
  }

  Future<void> _retainOriginal(String id) async {
    final pending = Zone.current[#pending];
    pending[id] ??= _serverDataBox.get(id) ?? await account.db.getResource(id);
  }

  Future<void> track(Future<void> Function() fn, {bool clearUntouched = true}) async {
    final pending = await runZonedGuarded(() async {
      await fn();
      return (Zone.current[#pending] as Map).cast<String, Resource?>();
    }, (err, stack) {}, zoneValues: {
      #pending: <String, Resource?>{},
    });
    if (pending != null) {
      var untouchedKeys = const <String>{};
      if (clearUntouched) {
        untouchedKeys = Set.from(_serverDataBox.keys);
        untouchedKeys.retainWhere((key) => !pending.containsKey(key));
      }
      // Avoid unnecessary disk writes
      pending.removeWhere((key, value) => _serverDataBox.containsKey(key) && _serverDataBox.get(key) == value);
      await _serverDataBox.putAll(pending);
      await _serverDataBox.deleteAll(untouchedKeys);
      await _serverDataBox.flush();
    }
  }

  Future<void> revert(String id) {
    final r = _serverDataBox.get(id);

    if (r == null) {
      return account.db.resources.deleteWhere((f) => f.id.equals(id));
    } else {
      return account.db.resources.replaceOne(r);
    }
  }

  void processServerUpdates(Iterable<ResourcesCompanion> updates) {
    for (final r in updates) {
      if (_serverDataBox.containsKey(r.id.value)) {
        _serverDataBox.put(r.id.value, _serverDataBox.get(r.id.value)?.copyWithCompanion(r));
      }
    }
  }

  QueryInterceptor newInterceptor(bool clearUntouched) {
    return Interceptor(tracker: this, clearUntouched: clearUntouched);
  }

  Future<void> _trackServerResources(Map<String, Resource?> serverResources, bool clearUntouched) async {}
}

class Interceptor extends QueryInterceptor {
  final LocalChangeTracker tracker;
  final bool clearUntouched;
  late final AppDatabase db;
  final Map<String, Resource?> serverData = {};

  Interceptor({required this.tracker, required this.clearUntouched});

  @override
  TransactionExecutor beginTransaction(QueryExecutor parent) {
    final tx = super.beginTransaction(parent);
    db = AppDatabase.fromExecutor(accountId: "", executor: tx);
    return tx;
  }

  @override
  Future<int> runUpdate(QueryExecutor executor, String statement, List<Object?> args) async {
    if (statement.toLowerCase().startsWith("update \"resources\"")) {
      await retainOriginal(args.last.toString());
    }
    return super.runUpdate(executor, statement, args);
  }

  @override
  Future<int> runInsert(QueryExecutor executor, String statement, List<Object?> args) async {
    final lower = statement.toLowerCase();
    if (lower.startsWith("insert into \"resources\"") || lower.startsWith("insert or replace into \"resources\"")) {
      await retainOriginal(args.first.toString());
    }
    return super.runInsert(executor, statement, args);
  }

  Future<void> retainOriginal(String id) async {
    serverData[id] ??= tracker._serverDataBox.get(id) ?? await db.getResource(id);
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    super.commitTransaction(inner);
    await tracker._trackServerResources(serverData, clearUntouched);
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
