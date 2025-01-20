import 'dart:io';

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
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/parsers/resources.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:phylum/libphylum/util/uuid.dart';

class ResourceRepository {
  final PhylumAccount account;

  ResourceRepository({required this.account});

  Future<ApiResult> requestResource(String id) async {
    return account.apiClient.sendRequest(
      ResourceLsRequest(id),
      (request, response) => parseJsonMapResponse(response, FullResourceResponse.fromResponse),
    );
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
    required String name,
    NameConflictResolution conflictResolution = nameConflictError,
  }) async {
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
          break;
        case nameConflictDelete:
          deletedId = existing.first.id;
          break;
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
    required String name,
    required String parent,
    required NameConflictResolution conflictResolution,
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
    await account.addAction(ResourceMoveAction(
      resourceId: resource.id,
      parent: parent,
      resourceName: name,
      conflictResolution: conflictResolution,
      description: parent == resource.parent ? 'Renaming ${resource.name} to $localName' : 'Moving ${resource.name}',
      modified: DateTime.now(),
      localName: localName,
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
}
