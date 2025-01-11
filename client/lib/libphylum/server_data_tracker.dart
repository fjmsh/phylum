import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';

class ServerResourceStateTracker {
  final PhylumAccount account;
  late final Box<Resource?> _box;

  ServerResourceStateTracker({required this.account});

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(const ResourceAdapter().typeId)) {
      Hive.registerAdapter(const ResourceAdapter());
    }
    _box = await account.openBox('server_data');
  }

  Resource? getServerResource(String id) {
    return _box.get(id);
  }

  QueryInterceptor newInterceptor(bool clearPrevious) {
    return Interceptor(tracker: this, clearPrevious: clearPrevious);
  }

  Future<void> _trackServerResources(Map<String, Resource?> serverResources, bool clearUnused) async {
    var unusedKeys = const <String>{};
    if (clearUnused) {
      unusedKeys = Set.from(_box.keys);
      unusedKeys.retainWhere((key) => !serverResources.containsKey(key));
    }
    // Avoid unnecessary disk writes
    serverResources.removeWhere((key, value) => _box.containsKey(key) && _box.get(key) == value);
    await _box.putAll(serverResources);
    await _box.deleteAll(unusedKeys);
    await _box.flush();
  }

  void update(Iterable<ResourcesCompanion> updates) {
    for (final r in updates) {
      if (_box.containsKey(r.id.value)) {
        _box.put(r.id.value, _box.get(r.id.value)?.copyWithCompanion(r));
      }
    }
  }
}

class Interceptor extends QueryInterceptor {
  final ServerResourceStateTracker tracker;
  final bool clearPrevious;
  late final AppDatabase db;
  final Map<String, Resource?> serverData = {};

  Interceptor({required this.tracker, required this.clearPrevious});

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
    serverData[id] ??= tracker.getServerResource(id) ?? await db.getResource(id);
  }

  @override
  Future<void> commitTransaction(TransactionExecutor inner) async {
    super.commitTransaction(inner);
    await tracker._trackServerResources(serverData, clearPrevious);
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
