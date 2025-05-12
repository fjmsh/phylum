import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:file_selector/file_selector.dart';
import 'package:hive_ce/hive.dart';
import 'package:mime/mime.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path/path.dart';
import 'package:phylum/libphylum/actions/action_resource_copy.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/local_upload_errors.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_info_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/libphylum/util/uuid.dart';
import 'package:phylum/util/permissions.dart';

const performLocalNameCheck = true;
const _remoteResourcesBoxName = 'remote_resources';

typedef CopyMoveFn = Future<String> Function({
  required Resource resource,
  required String name,
  required String parent,
  required NameConflictResolution conflictResolution,
});

class ResourceRepository extends Repository<PhylumAccount, Resource> {
  late final PhylumAccount _account;
  late final LazyBox<Resource?> _remoteDataBox;

  ResourceRepository();

  @override
  Future<Map<String, Resource?>> initializeAndRestoreRemoteData(PhylumAccount account) async {
    if (!Hive.isAdapterRegistered(const ResourceAdapter().typeId)) {
      Hive.registerAdapter(const ResourceAdapter());
    }
    final box = await account.openBox<Resource>(_remoteResourcesBoxName);
    final remoteData = Map<String, Resource?>.fromIterable(box.keys, value: (key) => box.get(key));
    await box.close();
    _account = account;
    _remoteDataBox = await account.openLazyBox(_remoteResourcesBoxName);
    return remoteData;
  }

  Future<ApiResult> requestResource(String id) async {
    return _account.apiClient.sendRequest(
      ResourceInfoRequest(id),
      (request, response) =>
          parseJsonMapResponse(response, (data) => ResourceInfoResponse.fromResponse(data, _account.userEmail)),
    );
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
    final data = await _account.db.getResource(objectId);
    return data;
  }

  @override
  Future<void> save(String objectId, Resource data) {
    return _account.db.resources.insertOne(data, mode: InsertMode.insertOrReplace);
  }

  @override
  Future<void> delete(String objectId) async {
    await _account.db.resources.deleteWhere((r) => r.id.equals(objectId));
  }

  Future<String> mkdir({
    required String parent,
    required String name,
    required NameConflictResolution conflictResolution,
    required Permission userPermission,
    String? id,
  }) async {
    id ??= generateUuid();
    String localName = name;
    String? deletedId;
    if (performLocalNameCheck) {
      var existing = await _account.db.getResourcesByName(parent: parent, name: name);
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
    }

    await _account.addAction(ResourceMkdirAction(
      parent: parent,
      resourceName: name,
      resourceId: id,
      conflictResolution: conflictResolution,
      timestamp: DateTime.now(),
      localName: localName,
      deletedId: deletedId,
      userPermission: userPermission,
    ));

    return id;
  }

  Future<String> upload({
    required String parent,
    required String name,
    required Permission userPermission,
    XFile? file,
    String? path,
    NameConflictResolution conflictResolution = nameConflictError,
  }) async {
    String id = generateUuid();
    String localName = name;
    String? deletedId;
    if (performLocalNameCheck) {
      var existing = await _account.db.getResourcesByName(parent: parent, name: name);
      if (existing.isNotEmpty) {
        switch (conflictResolution) {
          case nameConflictError:
            throw NameConflictException(existing.first);
          case nameConflictRename:
            localName = await _createUniqueName(existing, parent, name);
            break;
          case nameConflictOverwrite:
            id = existing.first.id;
            break;
          case nameConflictDelete:
            deletedId = existing.first.id;
            break;
          default:
            throw UnsupportedError('Unsupported conflict resolution');
        }
      }
    }
    assert((file == null) != (path == null));
    final size = (file != null) ? (await file.length()) : (await File(path!).length());
    final contentType = file?.mimeType ?? lookupMimeType(file?.name ?? path!) ?? 'application/octet-stream';
    final contents = (file != null) ? await file.readAsBytes() : (await File(path!).readAsBytes());
    await _account.addAction(
        ResourceUploadAction(
          resourceId: id,
          parent: parent,
          resourceName: name,
          conflictResolution: conflictResolution,
          timestamp: DateTime.now(),
          size: size,
          contentType: contentType,
          localName: localName,
          deletedId: deletedId,
          userPermission: userPermission,
        ),
        data: contents);
    return id;
  }

  Future<String> move({
    required Resource resource,
    required String name,
    required String parent,
    required NameConflictResolution conflictResolution,
  }) async {
    String localName = name;
    String? deletedId;
    if (performLocalNameCheck) {
      final parents = await _account.db.parents(parent).get();
      for (final p in parents) {
        if (p.id == resource.id) {
          throw DestinationCycleException(resource);
        }
      }

      var existing = await _account.db.getResourcesByName(parent: parent, name: name);
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
    }
    await _account.addAction(ResourceMoveAction(
      resourceId: resource.id,
      parent: parent,
      resourceName: name,
      conflictResolution: conflictResolution,
      description: parent == resource.parent ? 'Renaming ${resource.name} to $localName' : 'Moving ${resource.name}',
      timestamp: DateTime.now(),
      localName: localName,
      oldParent: parent == resource.parent ? null : resource.parent,
      deletedId: deletedId,
    ));
    return resource.id;
  }

  Future<String> copy({
    required Resource resource,
    required String parent,
    required String name,
    required NameConflictResolution conflictResolution,
  }) async {
    if (parent == resource.parent && name == resource.name) {
      name = '${basenameWithoutExtension(name)} - copy${extension(name)}';
    }

    String id = generateUuid();
    String? deletedId;
    String localName = name;
    if (performLocalNameCheck) {
      var existing = await _account.db.getResourcesByName(parent: parent, name: name);
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
    }
    await _account.addAction(ResourceCopyAction(
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
      userPermission: resource.userPermission,
    ));
    return id;
  }

  Future<String> _createUniqueName(List<Resource> existing, String parent, String name) async {
    String localName = name;
    int counter = 1;
    while (existing.isNotEmpty) {
      localName = '${basenameWithoutExtension(name)} (${counter++})${extension(name)}';
      existing = await _account.db.getResourcesByName(parent: parent, name: localName);
    }
    return localName;
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
