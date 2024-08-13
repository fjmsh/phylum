import 'dart:async';

import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
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
  dynamic get tag => 'resourceDetails';

  @override
  Future<MultipartFile> get file => MultipartFile.fromPath('contents', path, filename: resourceName);

  final String id;
  final String parent;
  final String resourceName;
  final String path;

  ResourceUploadAction._({
    required this.id,
    required this.parent,
    required this.resourceName,
    required this.path,
  });

  ResourceUploadAction({
    required String parent,
    required String resourceName,
    required String path,
  }) : this._(id: (const Uuid()).v4(), parent: parent, resourceName: resourceName, path: path);

  static ResourceUploadAction fromMap(Map<String, dynamic> map, dynamic data) {
    return ResourceUploadAction._(
      id: map['id'],
      parent: map['parent'],
      resourceName: map['dirName'],
      path: map['path'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return "Uploading $resourceName";
  }

  @override
  FutureOr<void> applyOptimisticUpdate(PhylumAccount account) {}

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {}

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'parent': parent,
        'resourceName': resourceName,
        'path': path,
      };

  @override
  Map<String, String> generateFormFields() {
    return {
      'parent_id': parent,
      'name': resourceName,
    };
  }
}
