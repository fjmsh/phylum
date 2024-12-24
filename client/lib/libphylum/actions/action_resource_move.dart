import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMoveAction extends PhylumAction with JsonApiAction, ResourceBindAction {
  static const kActionName = 'resourceMove';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mv/$resourceId';

  final String resourceId;
  @override
  final String parent;
  String _resourceName;
  @override
  String get resourceName => _resourceName;
  final DateTime modified;
  final String description;

  ResourceMoveAction._({
    required this.resourceId,
    required this.parent,
    required String resourceName,
    required this.description,
    required this.modified,
  }) : _resourceName = resourceName;

  ResourceMoveAction({
    required Resource r,
    String? name,
    String? parent,
  }) : this._(
          resourceId: r.id,
          parent: parent ?? r.parent!,
          resourceName: name ?? r.name,
          description: name == null ? 'Moving ${r.name}' : 'Renaming ${r.name} to $name',
          modified: DateTime.now(),
        );

  static ResourceMoveAction fromMap(Map<String, dynamic> map) {
    return ResourceMoveAction._(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      description: map['description'],
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
    );
  }

  @override
  String generateDescription() {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'target': '$parent:$resourceName',
    };
  }

  @override
  Future<void> initialize() {
    return account.resourceRepository.trackServerData(resourceId);
  }

  @override
  Future<void> dispose() {
    return account.resourceRepository.stopTrackingServerData(resourceId);
  }

  @override
  Future<void> applyOptimisticUpdate() {
    return account.resourceRepository.updateResource(
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
    return account.resourceRepository.updateResource(
      resourceId,
      (o) => o(
        name: Value(serverData.name),
        parent: Value(serverData.parent),
        modified: Value(serverData.modified),
      ),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'description': description,
        'modified': modified.millisecondsSinceEpoch,
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
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceCreateAction && action.resourceId == parent) ||
      (action is ResourceMoveAction && action.resourceId == resourceId);
}
