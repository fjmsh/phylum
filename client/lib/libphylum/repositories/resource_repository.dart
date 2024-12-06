import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';

class ResourceRepository {
  final PhylumAccount account;
  late final Box<Resource> _serverDataBox;
  late final Box<int> _serverDataCountsBox;

  ResourceRepository({required this.account});

  Future<void> initialize() async {
    if (!Hive.isAdapterRegistered(const ResourceAdapter().typeId)) {
      Hive.registerAdapter(const ResourceAdapter());
    }
    _serverDataBox = await account.openBox('server_data');
    _serverDataCountsBox = await account.openBox('server_data_counts');
  }

  Future<ApiResult> requestResource(String id) async {
    return account.apiClient.sendRequest(ResourceLsRequest(id), callback: (request, response) async {
      if (response is PhylumApiSuccessResponse) {
        await processResourceResponse(response.data);
      }
    });
  }

  Future<Resource?> getResource(String id) {
    return _selectResource(id).getSingleOrNull();
  }

  Stream<Resource?> watchResource(String id) {
    return _selectResource(id).watchSingleOrNull();
  }

  Future<List<Resource>> getResources(Iterable<String> ids) {
    return _selectResources(ids).get();
  }

  Stream<List<Resource>> watchChildren(String id) {
    return (_selectChildren(id)..orderBy([(u) => OrderingTerm.desc(u.dir), (u) => OrderingTerm.asc(u.name.collate(Collate.noCase))])).watch();
  }

  Stream<List<ParentsResult>> watchParents(String id) {
    return account.db.parents(id).watch();
  }

  SimpleSelectStatement<Resources, Resource> _selectResource(String id) {
    return account.db.resources.select()..where((f) => f.id.equals(id) & f.deleted.equals(false));
  }

  SimpleSelectStatement<Resources, Resource> _selectChildren(String id) {
    return account.db.resources.select()..where((f) => f.parent.equals(id) & f.deleted.equals(false));
  }

  SimpleSelectStatement<Resources, Resource> _selectResources(Iterable<String> ids) {
    return account.db.resources.select()..where((f) => f.id.isIn(ids));
  }

  Future<void> trackServerData(String id) async {
    final count = _serverDataCountsBox.get(id) ?? 0;
    if (count == 0) {
      final r = await _selectResource(id).getSingle();
      await Future.wait([
        _serverDataCountsBox.put(id, 1),
        _serverDataBox.put(id, r),
      ]);
    } else {
      return _serverDataCountsBox.put(id, count + 1);
    }
  }

  Future<void> stopTrackingServerData(String id) async {
    final count = _serverDataCountsBox.get(id) ?? 0;
    if (count <= 0) {
      throw Exception('Cannot stop tracking server data without first starting');
    }
    if (count == 1) {
      await Future.wait([
        _serverDataCountsBox.delete(id),
        _serverDataBox.delete(id),
      ]);
    } else {
      return _serverDataCountsBox.put(id, count - 1);
    }
  }

  Resource? getServerData(String id) {
    return _serverDataBox.get(id);
  }

  Future<int> createResource(String id, bool dir, String parent, String name, String contentType) {
    return account.db.resources.insertOne(
      ResourcesCompanion.insert(
        id: id,
        name: name,
        parent: Value(parent),
        dir: dir,
        created: Value(DateTime.now()),
        modified: Value(DateTime.now()),
        contentSize: Value(0),
        contentSha256: Value(""),
        contentType: Value(contentType),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<int> updateResource(String id, Insertable<Resource> Function($ResourcesUpdateCompanionBuilder o) fn) {
    return account.db.managers.resources.filter((f) => f.id.equals(id)).update(fn);
  }

  Future<int> deleteResource(String id) {
    return account.db.resources.deleteWhere((f) => f.id.equals(id));
  }

  Future processResourceResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final (insert, update) = await parseFullResourceObject(data);
    await db.batch((batch) {
      for (final u in update) {
        batch.update(db.resources, u, where: (o) => o.id.equals(u.id.value));
      }
      batch.insertAllOnConflictUpdate(db.resources, insert);
    });
    for (final r in insert) {
      final serverData = _serverDataBox.get(r.id.value);
      if (serverData != null) {
        _serverDataBox.put(r.id.value, serverData.copyWithCompanion(r));
      }
    }
  }

  Future processResourceUpdateResponse(String id, Map<String, dynamic> data) async {
    final r = parsePartialResourceObject(data);
    final update = (account.db.resources.update()..where((o) => o.id.equals(id)));
    await update.write(r);
    final serverData = _serverDataBox.get(r.id.value);
    if (serverData != null) {
      _serverDataBox.put(r.id.value, serverData.copyWithCompanion(r));
    }
  }

  Future<(Iterable<ResourcesCompanion>, Iterable<ResourcesCompanion>)> parseFullResourceObject(Map<String, dynamic> data) async {
    final ancestors = (data['ancestors'] as List).cast<Map>().map(
          (a) => parseResourceAncestor(a.cast<String, dynamic>()).copyWith(dir: Value(true)),
        );

    final info = parseResourceObject(data['info'])..copyWith(lastRefresh: Value(DateTime.now()));
    final id = info.id.value;
    final db = account.db;

    final existing = Set.of(await (db.select(db.resources)..where((t) => t.parent.equals(id))).map((r) => r.id).get());
    final children = (data['children'] as List).cast<Map>().map((c) {
      existing.remove(c['id']);
      return parseResourceObject(c.cast<String, dynamic>());
    });
    final removeParentRelation = existing.map((id) => ResourcesCompanion(id: Value(id), parent: Value(null)));
    return ([...ancestors, info, ...children], removeParentRelation);
  }

  ResourcesCompanion parseResourceObject(Map<String, dynamic> data) {
    return ResourcesCompanion(
      id: Value(data['id']),
      parent: Value(data['parent']),
      name: Value(data['name']),
      dir: Value(data['dir']),
      created: Value(DateTime.parse(data['created'])),
      modified: Value(DateTime.parse(data['modified'])),
      deleted: Value(data['deleted'] != null),
      contentSize: Value(data['c_size']),
      contentSha256: Value(data['c_sha256']),
      contentType: Value(data['c_type']),
      permissions: data['permissions'].isEmpty ? Value(null) : Value(data['permissions']),
      publinks: data['publinks'].isEmpty ? Value(null) : Value(data['publinks']),
      lastRefresh: Value(DateTime.now()),
    );
  }

  ResourcesCompanion parseResourceAncestor(Map<String, dynamic> data) {
    return ResourcesCompanion(
        id: Value(data['id']),
        parent: Value(data['parent']),
        name: Value(data['name']),
        dir: Value(true),
        permissions: data['permissions'].isEmpty ? Value(null) : Value(data['permissions']));
  }

  ResourcesCompanion parsePartialResourceObject(Map<String, dynamic> data) {
    return ResourcesCompanion(
      id: Value.absentIfNull(data['id']),
      parent: Value.absentIfNull(data['parent']),
      name: Value.absentIfNull(data['name']),
      dir: Value.absentIfNull(data['dir']),
      created: Value.absentIfNull(data.containsKey('created') ? DateTime.parse(data['created']) : null),
      modified: Value.absentIfNull(data.containsKey('modified') ? DateTime.parse(data['modified']) : null),
      deleted: Value.absentIfNull(data.containsKey('deleted') ? data['deleted'] != null : null),
      contentSize: Value.absentIfNull(data['c_size']),
      contentSha256: Value.absentIfNull(data['c_sha256']),
      contentType: Value.absentIfNull(data['c_type']),
      permissions: data.containsKey('permissions')
          ? data['permissions'].isEmpty
              ? Value(null)
              : Value(data['permissions'])
          : Value.absent(),
      publinks: data.containsKey('publinks')
          ? data['publinks'].isEmpty
              ? Value(null)
              : Value(data['publinks'])
          : Value.absent(),
    );
  }
}

class ResourceAdapter implements TypeAdapter<Resource> {
  const ResourceAdapter();

  @override
  int get typeId => 1;

  @override
  Resource read(BinaryReader reader) {
    reader.readByte();
    return Resource.fromJson(json.decode(reader.readString()));
  }

  @override
  void write(BinaryWriter writer, Resource obj) {
    writer.writeByte(0); // Version marker, in case we need to change something in the future
    writer.writeString(obj.toJsonString());
  }
}
