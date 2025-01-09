import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:hive/hive.dart';
import 'package:mime/mime.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path/path.dart';
import 'package:phylum/libphylum/actions/action_resource_copy.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:phylum/libphylum/util/uuid.dart';

class ResourceRepository {
  final PhylumAccount account;
  late final Box<Resource> _serverDataBox;
  late final Box<int> _serverDataCountsBox;

  ResourceRepository({required this.account});

  get dest => null;

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

  Future<String> mkdir({
    required String parent,
    required String name,
    required NameConflictResolution conflictResolution,
    String? id,
  }) async {
    var existing = await account.db.getResourcesByName(parent: parent, name: name);
    String? deletedId;
    String localName = name;
    if (existing.isNotEmpty) {
      switch (conflictResolution) {
        case nameConflictError:
          throw NameConflictException(existing.first);
        case nameConflictRename:
          localName = await _createUniqueName(existing, parent, name);
          break;
        case nameConflictOverwrite:
        case nameConflictDelete:
          conflictResolution = nameConflictDelete;
          deletedId = existing.first.id;
          break;
        default:
          throw UnsupportedError('Unsupported conflict resolution');
      }
    }

    id ??= generateUuid();
    await account.addAction(ResourceMkdirAction(
      parent: parent,
      resourceName: name,
      resourceId: id,
      conflictResolution: conflictResolution,
      timestamp: DateTime.now(),
      localName: localName,
      deletedId: deletedId,
    ));

    return id;
  }

  Future<String> upload({
    required String parent,
    required String path,
    String? name,
    NameConflictResolution conflictResolution = nameConflictError,
  }) async {
    name ??= basename(path);
    var existing = await account.db.getResourcesByName(parent: parent, name: name);
    String localName = name;
    String id = generateUuid();
    String? deletedId;
    if (existing.isNotEmpty) {
      switch (conflictResolution) {
        case nameConflictError:
          throw NameConflictException(existing.first);
        case nameConflictRename:
          localName = await _createUniqueName(existing, parent, name);
          break;
        case nameConflictOverwrite:
          id = existing.first.id;
        case nameConflictDelete:
          deletedId = existing.first.id;
        default:
          throw UnsupportedError('Unsupported conflict resolution');
      }
    }
    final f = File(path);
    final size = await f.length();
    final contentType = lookupMimeType(path) ?? 'application/octet-stream';
    await account.addAction(ResourceUploadAction(
      resourceId: id,
      parent: parent,
      resourceName: name,
      conflictResolution: conflictResolution,
      timestamp: DateTime.now(),
      path: path,
      size: size,
      contentType: contentType,
      localName: localName,
      deletedId: deletedId,
    ));
    return id;
  }

  Future<String> move({
    required Resource resource,
    required NameConflictResolution conflictResolution,
    String? parent,
    String? name,
  }) async {
    assert(parent != null || name != null);
    parent ??= resource.parent!;
    name ??= resource.name;
    var existing = await account.db.getResourcesByName(parent: parent, name: name);
    String? deletedId;
    String localName = name;
    if (existing.isNotEmpty) {
      switch (conflictResolution) {
        case nameConflictError:
          throw NameConflictException(existing.first);
        case nameConflictRename:
          localName = await _createUniqueName(existing, parent, name);
          break;
        case nameConflictOverwrite:
        case nameConflictDelete:
          conflictResolution = nameConflictDelete;
          deletedId = existing.first.id;
          break;
        default:
          throw UnsupportedError('Unsupported conflict resolution');
      }
    }
    await account.addAction(ResourceMoveAction(
      resourceId: resource.id,
      parent: parent,
      resourceName: name,
      conflictResolution: conflictResolution,
      description: 'Moving $name',
      modified: DateTime.now(),
      localName: localName,
      deletedId: deletedId,
    ));
    return resource.id;
  }

  Future<String> copy({
    required Resource resource,
    required String parent,
    required NameConflictResolution conflictResolution,
    String? name,
  }) async {
    name ??= resource.name;
    if (parent == resource.parent && name == resource.name) {
      name = '${basenameWithoutExtension(name)} - copy${extension(name)}';
    }

    String id = generateUuid();
    var existing = await account.db.getResourcesByName(parent: parent, name: name);
    String? deletedId;
    String localName = name;
    if (existing.isNotEmpty) {
      switch (conflictResolution) {
        case nameConflictError:
          throw NameConflictException(existing.first);
        case nameConflictRename:
          localName = await _createUniqueName(existing, parent, name);
          break;
        case nameConflictOverwrite:
        case nameConflictDelete:
          conflictResolution = nameConflictDelete;
          deletedId = existing.first.id;
          break;
        default:
          throw UnsupportedError('Unsupported conflict resolution');
      }
    }
    await account.addAction(ResourceCopyAction(
      srcId: resource.id,
      resourceId: id,
      parent: parent,
      resourceName: name,
      conflictResolution: nameConflictRename,
      dir: resource.dir,
      localName: localName,
      contentType: resource.contentType,
      contentLength: resource.contentLength,
      contentSha256: resource.contentSha256,
      description: 'Copying ${resource.name}',
      timestamp: DateTime.now(),
      deletedId: deletedId,
    ));
    return id;
  }

  Future<String> _createUniqueName(List<Resource> existing, String parent, String name) async {
    String localName = name;
    int counter = 1;
    while (existing.isNotEmpty) {
      localName = '${basenameWithoutExtension(name)} (${counter++})${extension(name)}';
      existing = await account.db.getResourcesByName(parent: parent, name: localName);
    }
    return localName;
  }

  Future<void> trackServerData(String id) async {
    final count = _serverDataCountsBox.get(id) ?? 0;
    if (count == 0) {
      final r = await account.db.getResource(id);
      assert(r != null);
      await Future.wait([
        _serverDataCountsBox.put(id, 1),
        _serverDataBox.put(id, r!),
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

  Future<ResourcesCompanion> processResourceUpdateResponse(String id, Map<String, dynamic> data) async {
    final r = parsePartialResourceObject(data, id);
    final update = (account.db.resources.update()..where((o) => o.id.equals(r.id.value)));
    await update.write(r);
    final serverData = _serverDataBox.get(r.id.value);
    if (serverData != null) {
      _serverDataBox.put(r.id.value, serverData.copyWithCompanion(r));
    }
    return r;
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
    contentLength: Value(data['c_len']),
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

ResourcesCompanion parsePartialResourceObject(Map<String, dynamic> data, [String? id]) {
  return ResourcesCompanion(
    id: Value(data['id'] ?? id),
    parent: Value.absentIfNull(data['parent']),
    name: Value.absentIfNull(data['name']),
    dir: Value.absentIfNull(data['dir']),
    created: Value.absentIfNull(data.containsKey('created') ? DateTime.parse(data['created']) : null),
    modified: Value.absentIfNull(data.containsKey('modified') ? DateTime.parse(data['modified']) : null),
    deleted: Value.absentIfNull(data.containsKey('deleted') ? data['deleted'] != null : null),
    contentLength: Value.absentIfNull(data['c_len']),
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
