import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceCopyAction extends ResourceCreateAction with JsonApiAction {
  static const kActionName = 'resourceCopy';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/cp/$srcId';

  final String srcId;
  @override
  final String resourceId;
  @override
  final String parent;
  String _resourceName;
  @override
  String get resourceName => _resourceName;
  final String description;
  final bool dir;

  ResourceCopyAction._({
    required this.srcId,
    required this.resourceId,
    required this.parent,
    required String resourceName,
    required this.dir,
    required this.description,
  }) : _resourceName = resourceName;

  ResourceCopyAction({
    required Resource src,
    required String resourceId,
    required String parent,
    required String resourceName,
  }) : this._(
          srcId: src.id,
          resourceId: resourceId,
          parent: parent,
          resourceName: resourceName,
          dir: src.dir,
          description: 'Copying ${src.name}',
        );

  static ResourceCopyAction fromMap(Map<String, dynamic> map) {
    return ResourceCopyAction._(
      srcId: map['srcId'],
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      dir: map['dir'],
      description: map['description'],
    );
  }

  @override
  String generateDescription() {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'id': resourceId,
      'target': '$parent:$resourceName',
    };
  }

  @override
  Future<void> applyOptimisticUpdate() {
    return account.resourceRepository.createResource(resourceId, dir, parent, resourceName, '');
  }

  @override
  Future<void> revertOptimisticUpdate() {
    return account.resourceRepository.deleteResource(resourceId);
  }

  @override
  Map<String, dynamic> toMap() => {
        'srcId': srcId,
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'dir': dir,
        'description': description,
      };

  @override
  FutureOr<void> processResponse(ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
    }
  }

  @override
  Future<void> updateResourceName(String resourceName) {
    _resourceName = resourceName;
    return update(revertOptimisticUpdate);
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == parent;
}
