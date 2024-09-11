import 'dart:async';
import 'dart:io';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_datastore.dart';
import 'package:uuid/uuid.dart';

class ResourceUploadAction extends ApiAction<PhylumAccount> with FileUploadApiAction {
  static const actionName = 'resourceUpload';
  @override
  String get name => actionName;

  @override
  String get method => 'PUT';

  @override
  String get endpoint => '/api/v1/resources/upload/$id';

  @override
  get tag => resourceSummaryResponse;

  @override
  Future<MultipartFile> get file => MultipartFile.fromPath('contents', path, filename: resourceName, contentType: MediaType.parse(contentType));

  final String id;
  final String parent;
  final String resourceName;
  final String path;
  final int size;
  final String contentType;

  ResourceUploadAction._(
      {required this.id, required this.parent, required this.resourceName, required this.path, required this.size, required this.contentType});

  static Future<ResourceUploadAction> fromPath({
    required String parent,
    required String resourceName,
    required String path,
  }) async {
    final f = File(path);
    final size = await f.length();
    return ResourceUploadAction._(
      id: (const Uuid()).v4(),
      parent: parent,
      resourceName: resourceName,
      path: path,
      size: size,
      contentType: lookupMimeType(path) ?? 'application/octet-stream',
    );
  }

  static ResourceUploadAction fromMap(Map<String, dynamic> map, dynamic data) {
    return ResourceUploadAction._(
      id: map['id'],
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
  FutureOr<void> applyOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.createResource(id, true, parent, resourceName, contentType);
  }

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.deleteResource(id);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
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
}
