import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/util/uuid.dart';

import 'action_resource_bind.dart';

class ResourceUploadAction extends ResourceCreateAction with FileUploadApiAction {
  static const kActionName = 'resourceUpload';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'PUT';

  @override
  String get endpoint => '/api/v1/fs/upload/$resourceId';

  @override
  Future<MultipartFile> get file => MultipartFile.fromPath('contents', path, filename: resourceName, contentType: MediaType.parse(contentType));

  final String path;
  final int size;
  final String contentType;
  final DateTime timestamp;

  ResourceUploadAction._({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.path,
    required this.size,
    required this.contentType,
    required this.timestamp,
  });

  static Future<ResourceUploadAction> fromPath({
    required String parent,
    required String resourceName,
    required String path,
    required ResourceBindConflictResolution conflictResolution,
  }) async {
    final f = File(path);
    final size = await f.length();
    return ResourceUploadAction._(
      resourceId: generateUuid(),
      parent: parent,
      resourceName: resourceName,
      conflictResolution: conflictResolution,
      path: path,
      size: size,
      contentType: lookupMimeType(path) ?? 'application/octet-stream',
      timestamp: DateTime.now(),
    );
  }

  static ResourceUploadAction fromMap(Map<String, dynamic> map) {
    return ResourceUploadAction._(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      path: map['path'],
      size: map['size'],
      contentType: map['contentType'],
      timestamp: map['timestamp'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'conflictResolution': conflictResolution,
        'path': path,
        'size': size,
        'contentType': contentType,
        'timestamp': timestamp,
      };

  @override
  String generateDescription() {
    return "Uploading $resourceName";
  }

  @override
  Future<void> applyOptimisticUpdate() async {
    await account.db.createResource(resourceId, parent, resourceName, false, timestamp);
    await account.db.updateResource(
      resourceId,
      (o) => o(
        contentType: Value(contentType),
        contentLength: Value(size),
      ),
    );
  }

  @override
  Future<void> revertOptimisticUpdate() {
    return account.db.deleteResource(resourceId);
  }

  @override
  Map<String, String> generateFormFields() {
    return {
      'parent_id': parent,
      'name': resourceName,
      'conflict': conflictResolution.toString(),
    };
  }

  @override
  bool dependsOn(PhylumAction action) => (action is ResourceCreateAction && action.resourceId == parent);
}
