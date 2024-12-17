import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/util/uuid.dart';

class ResourceUploadAction extends PhylumAction with FileUploadApiAction, ResourceCreateAction, ResourceBindAction {
  static const actionName = 'resourceUpload';
  @override
  String get name => actionName;

  @override
  String get method => 'PUT';

  @override
  String get endpoint => '/api/v1/fs/upload/$resourceId';

  @override
  Future<MultipartFile> get file => MultipartFile.fromPath('contents', path, filename: resourceName, contentType: MediaType.parse(contentType));

  @override
  final String resourceId;
  @override
  final String parent;
  @override
  final String resourceName;
  final String path;
  final int size;
  final String contentType;

  ResourceUploadAction._(
      {required this.resourceId,
      required this.parent,
      required this.resourceName,
      required this.path,
      required this.size,
      required this.contentType});

  static Future<ResourceUploadAction> fromPath({
    required String parent,
    required String resourceName,
    required String path,
  }) async {
    final f = File(path);
    final size = await f.length();
    return ResourceUploadAction._(
      resourceId: generateUuid(),
      parent: parent,
      resourceName: resourceName,
      path: path,
      size: size,
      contentType: lookupMimeType(path) ?? 'application/octet-stream',
    );
  }

  static ResourceUploadAction fromMap(Map<String, dynamic> map) {
    return ResourceUploadAction._(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      path: map['path'],
      size: map['size'],
      contentType: map['contentType'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return "Uploading $resourceName";
  }

  @override
  Future<void> applyOptimisticUpdate(PhylumAccount account) {
    return account.resourceRepository.createResource(resourceId, false, parent, resourceName, contentType);
  }

  @override
  Future<void> revertOptimisticUpdate(PhylumAccount account) {
    return account.resourceRepository.deleteResource(resourceId);
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'path': path,
        'size': size,
        'contentType': contentType,
      };

  @override
  Map<String, String> generateFormFields() {
    return {
      'parent_id': parent,
      'name': resourceName,
    };
  }

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
    }
  }

  @override
  ResourceBindAction copyWithResourceName(String resourceName) {
    return ResourceUploadAction._(
      resourceId: resourceId,
      parent: parent,
      resourceName: resourceName,
      path: path,
      size: size,
      contentType: contentType,
    );
  }

  @override
  bool dependsOn(PhylumAction action) => (action is ResourceCreateAction && action.resourceId == parent);
}
