import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMoveAction extends ResourceBindAction with JsonApiAction {
  static const kActionName = 'resourceMove';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mv/$resourceId';

  @override
  bool get trackServerData => true;

  final DateTime modified;
  final String description;

  ResourceMoveAction._({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    super.conflictResolution,
    required this.description,
    required this.modified,
  });

  ResourceMoveAction({
    required Resource r,
    String? name,
    String? parent,
    NameConflictResolution conflictResoltion = nameConflictError,
  }) : this._(
          resourceId: r.id,
          parent: parent ?? r.parent!,
          resourceName: name ?? r.name,
          conflictResolution: conflictResoltion,
          description: name == null ? 'Moving ${r.name}' : 'Renaming ${r.name} to $name',
          modified: DateTime.now(),
        );

  static ResourceMoveAction fromMap(Map<String, dynamic> map) {
    return ResourceMoveAction._(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      description: map['description'],
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
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
  Future<void> applyOptimisticUpdate() {
    return account.db.updateResource(
      resourceId,
      (o) => o(
        name: Value.absentIfNull(resourceName),
        parent: Value.absentIfNull(parent),
        modified: Value(modified),
      ),
    );
  }

  @override
  Future<void> revertOptimisticUpdate() {
    final serverData = account.resourceRepository.getServerData(resourceId)!;
    return account.db.updateResource(
      resourceId,
      (o) => o(
        name: Value(serverData.name),
        parent: Value(serverData.parent),
        modified: Value(serverData.modified),
      ),
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceCreateAction && action.resourceId == parent) ||
      (action is ResourceMoveAction && action.resourceId == resourceId);
}
