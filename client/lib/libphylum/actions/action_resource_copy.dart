import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
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
  final String description;
  final bool dir;

  ResourceCopyAction._({
    required this.srcId,
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.dir,
    required this.description,
  });

  ResourceCopyAction({
    required Resource src,
    required String resourceId,
    required String parent,
    required String resourceName,
    ResourceBindConflictResolution conflictResolution = resourceBindConflictResolutionNone,
  }) : this._(
          srcId: src.id,
          resourceId: resourceId,
          parent: parent,
          resourceName: resourceName,
          conflictResolution: conflictResolution,
          dir: src.dir,
          description: 'Copying ${src.name}',
        );

  factory ResourceCopyAction.fromMap(Map<String, dynamic> map) {
    return ResourceCopyAction._(
      srcId: map['srcId'],
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      dir: map['dir'],
      description: map['description'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'srcId': srcId,
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'conflictResolution': conflictResolution,
        'dir': dir,
        'description': description,
      };

  @override
  String generateDescription() {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'id': resourceId,
      'target': '$parent:$resourceName',
      'conflict': conflictResolution,
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
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == parent;
}
