import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceCopyAction extends PhylumAction with JsonApiAction, ResourceCreateAction {
  static const actionName = 'resourceCopy';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/cp/$srcId';

  final String srcId;
  @override
  final String resourceId;
  final String parentId;
  final String resourceName;
  final String description;
  final bool dir;

  ResourceCopyAction._({
    required this.srcId,
    required this.resourceId,
    required this.resourceName,
    required this.parentId,
    required this.dir,
    required this.description,
  });

  ResourceCopyAction({
    required Resource src,
    required String resourceId,
    required String resourceName,
    required String parentId,
  }) : this._(
          srcId: src.id,
          resourceId: resourceId,
          resourceName: resourceName,
          parentId: parentId,
          dir: src.dir,
          description: 'Copying ${src.name}',
        );

  static ResourceCopyAction fromMap(Map<String, dynamic> map) {
    return ResourceCopyAction._(
      srcId: map['srcId'],
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
      parentId: map['parentId'],
      dir: map['dir'],
      description: map['description'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'id': resourceId,
      'target': '$parentId:$resourceName',
    };
  }

  @override
  Future<void> applyOptimisticUpdate(PhylumAccount account) {
    return account.resourceRepository.createResource(resourceId, dir, parentId, resourceName, '');
  }

  @override
  Future<void> revertOptimisticUpdate(PhylumAccount account) {
    return account.resourceRepository.deleteResource(resourceId);
  }

  @override
  Map<String, dynamic> toMap() => {
        'srcId': srcId,
        'resourceId': resourceId,
        'resourceName': resourceName,
        'parentId': parentId,
        'dir': dir,
        'description': description,
      };

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.processResourceResponse(response.data);
    }
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == parentId;
}
