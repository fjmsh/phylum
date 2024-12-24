import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceCopyAction extends PhylumAction with JsonApiAction, ResourceCreateAction, ResourceBindAction {
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
  @override
  final String resourceName;
  final String description;
  final bool dir;

  ResourceCopyAction._({
    required this.srcId,
    required this.resourceId,
    required this.resourceName,
    required this.parent,
    required this.dir,
    required this.description,
  });

  ResourceCopyAction({
    required Resource src,
    required String resourceId,
    required String resourceName,
    required String parent,
  }) : this._(
          srcId: src.id,
          resourceId: resourceId,
          resourceName: resourceName,
          parent: parent,
          dir: src.dir,
          description: 'Copying ${src.name}',
        );

  static ResourceCopyAction fromMap(Map<String, dynamic> map) {
    return ResourceCopyAction._(
      srcId: map['srcId'],
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
      parent: map['parent'],
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
        'resourceName': resourceName,
        'parent': parent,
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
  ResourceBindAction copyWithResourceName(String resourceName) {
    return ResourceCopyAction._(
      srcId: srcId,
      resourceId: resourceId,
      resourceName: resourceName,
      parent: parent,
      dir: dir,
      description: description,
    );
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == parent;
}
