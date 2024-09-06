import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:http/http.dart';
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
  String get endpoint => '/v1/resources/upload/$id';

  @override
  get tag => resourceSummaryResponse;

  @override
  Future<MultipartFile> get file => MultipartFile.fromPath('contents', path, filename: resourceName);

  final String id;
  final String parent;
  final String resourceName;
  final String path;
  final int size;

  ResourceUploadAction._({
    required this.id,
    required this.parent,
    required this.resourceName,
    required this.path,
    required this.size,
  });

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
    );
  }

  static ResourceUploadAction fromMap(Map<String, dynamic> map, dynamic data) {
    return ResourceUploadAction._(
      id: map['id'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      path: map['path'],
      size: map['size'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return "Uploading $resourceName";
  }

  @override
  FutureOr<void> applyOptimisticUpdate(PhylumAccount account) {
    account.datastore.db.managers.resources.create((o) => o(
          dir: false,
          etag: "",
          size: size,
          id: id,
          parent: Value(parent),
          modified: DateTime.now(),
          name: resourceName,
        ));
  }

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {
    account.datastore.db.managers.resources.filter((f) => f.id.equals(id)).delete();
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'parent': parent,
        'resourceName': resourceName,
        'path': path,
        'size': size,
      };

  @override
  Map<String, String> generateFormFields() {
    return {
      'parent_id': parent,
      'name': resourceName,
    };
  }
}
