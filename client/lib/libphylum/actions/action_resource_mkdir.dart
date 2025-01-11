import 'dart:async';

import 'package:drift/drift.dart';
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
  final String localName;
  final String? deletedId;

  ResourceMkdirAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.timestamp,
    required this.localName,
    required this.deletedId,
  });

  static ResourceMkdirAction fromMap(Map<String, dynamic> map) {
    return ResourceMkdirAction(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      localName: map['localName'],
      deletedId: map['deletedId'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'resourceName': resourceName,
        'parent': parent,
        'conflictResolution': conflictResolution,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'localName': localName,
        'deletedId': deletedId,
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
  Future<void> applyOptimisticUpdate() async {
    await account.db.createResource(resourceId, parent, localName, true, timestamp);
    if (deletedId != null) {
      await account.db.updateResource(deletedId!, (u) => u(parent: Value(null)));
    }
  }

  @override
  Future<void> revertOptimisticUpdate() async {
    await account.db.deleteResource(resourceId);
    if (deletedId != null) {
      await account.serverResourceTracker.revert(deletedId!);
    }
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceMkdirAction && action.resourceId == parent;
}
