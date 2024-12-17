import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMoveAction extends PhylumAction with JsonApiAction, ResourceBindAction {
  static const actionName = 'resourceMove';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mv/$resourceId';

  final String resourceId;
  @override
  final String parent;
  @override
  final String resourceName;
  final DateTime modified;
  final String description;

  ResourceMoveAction._(
      {required this.resourceId, required this.resourceName, required this.parent, required this.description, required this.modified});

  ResourceMoveAction({
    required Resource r,
    String? parent,
    String? name,
  }) : this._(
          resourceId: r.id,
          resourceName: name ?? r.name,
          parent: parent ?? r.parent!,
          description: name == null ? 'Moving ${r.name}' : 'Renaming ${r.name} to $name',
          modified: DateTime.now(),
        );

  static ResourceMoveAction fromMap(Map<String, dynamic> map) {
    return ResourceMoveAction._(
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
      parent: map['parent'],
      description: map['description'],
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'target': '$parent:$resourceName',
    };
  }

  @override
  Future<void> initialize(PhylumAccount account) {
    return account.resourceRepository.trackServerData(resourceId);
  }

  @override
  Future<void> dispose(PhylumAccount account) {
    return account.resourceRepository.stopTrackingServerData(resourceId);
  }

  @override
  Future<void> applyOptimisticUpdate(PhylumAccount account) {
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
  Future<void> revertOptimisticUpdate(PhylumAccount account) {
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
        'resourceName': resourceName,
        'parent': parent,
        'description': description,
        'modified': modified.millisecondsSinceEpoch,
      };

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
    }
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceCreateAction && action.resourceId == parent) ||
      (action is ResourceMoveAction && action.resourceId == resourceId);
}
