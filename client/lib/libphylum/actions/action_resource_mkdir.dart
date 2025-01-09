import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMkdirAction extends ResourceCreateAction with JsonApiAction {
  static const kActionName = 'resourceMkdir';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mkdir/$resourceId';

  final DateTime timestamp;

  ResourceMkdirAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    super.conflictResolution,
    required this.timestamp,
  });

  static ResourceMkdirAction fromMap(Map<String, dynamic> map) {
    return ResourceMkdirAction(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      timestamp: map['timestamp'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'resourceName': resourceName,
        'parent': parent,
        'conflictResolution': conflictResolution,
        'timestamp': timestamp,
      };

  @override
  String generateDescription() {
    return "Creating Directory $resourceName";
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'parent_id': parent,
      'name': resourceName,
      'conflict': conflictResolution,
    };
  }

  @override
  Future<void> applyOptimisticUpdate() {
    return account.db.createResource(resourceId, parent, resourceName, true, timestamp);
  }

  @override
  Future<void> revertOptimisticUpdate() {
    return account.db.deleteResource(resourceId);
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceMkdirAction && action.resourceId == parent;
}
