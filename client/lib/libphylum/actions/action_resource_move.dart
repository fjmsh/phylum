import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMoveAction extends ResourceBindAction with JsonApiAction {
  static const kActionName = 'resourceMove';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mv/$resourceId';

  final DateTime modified;
  final String description;
  final String localName;
  final String? deletedId;

  ResourceMoveAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.description,
    required this.modified,
    required this.localName,
    required this.deletedId,
  });

  static ResourceMoveAction fromMap(Map<String, dynamic> map) {
    return ResourceMoveAction(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      description: map['description'],
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
      localName: map['localName'],
      deletedId: map['deletedId'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'conflictResolution': conflictResolution,
        'description': description,
        'modified': modified.millisecondsSinceEpoch,
        'localName': localName,
        'deletedId': deletedId,
      };

  @override
  String generateDescription() {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'target': '$parent:$resourceName',
      'conflict': conflictResolution,
    };
  }

  @override
  Future<void> applyOptimisticUpdate() async {
    await account.localChangeTracker.update(
      resourceId,
      ResourcesCompanion(
        name: Value.absentIfNull(localName),
        parent: Value.absentIfNull(parent),
        modified: Value(modified),
      ),
    );
    if (deletedId != null) {
      await account.localChangeTracker.update(deletedId!, ResourcesCompanion(parent: Value(null)));
    }
  }

  @override
  Future<void> revertOptimisticUpdate() async {
    await account.localChangeTracker.revert(resourceId);
    if (deletedId != null) {
      await account.localChangeTracker.revert(deletedId!);
    }
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceCreateAction && action.resourceId == parent) ||
      (action is ResourceMoveAction && action.resourceId == resourceId);
}
