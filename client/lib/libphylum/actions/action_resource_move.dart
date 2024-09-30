import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMoveAction extends PhylumAction with JsonApiAction {
  static const actionName = 'resourceMove';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/resources/move/$resourceId';

  final String resourceId;
  final String? parent;
  final String oldParent;
  final String? resourceName;
  final String oldName;
  final String description;

  ResourceMoveAction._({
    required this.resourceId,
    required this.resourceName,
    required this.parent,
    required this.oldName,
    required this.oldParent,
    required this.description,
  }) : assert(resourceName != null || parent != null);

  ResourceMoveAction({
    required Resource r,
    Resource? parent,
    String? name,
  }) : this._(
          resourceId: r.id,
          resourceName: name,
          parent: parent?.id,
          oldName: r.name,
          oldParent: r.parent!,
          description: name == null ? 'Moving ${r.name}' : 'Renaming ${r.name} to $name',
        );

  static ResourceMoveAction fromMap(Map<String, dynamic> map) {
    return ResourceMoveAction._(
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
      parent: map['parent'],
      oldName: map['oldName'],
      oldParent: map['oldParent'],
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
      'name': resourceName,
      'parent_id': parent,
    };
  }

  @override
  FutureOr applyOptimisticUpdate(PhylumAccount account) {
    return account.resourceRepository.updateResource(
      resourceId,
      (o) => o(
        name: Value.absentIfNull(resourceName),
        parent: Value.absentIfNull(parent),
      ),
    );
  }

  @override
  FutureOr revertOptimisticUpdate(PhylumAccount account) {
    return account.resourceRepository.updateResource(
      resourceId,
      (o) => o(
        name: Value.absentIfNull(oldName),
        parent: Value.absentIfNull(oldParent),
      ),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'resourceName': resourceName,
        'parent': parent,
        'oldName': oldName,
        'oldParent': oldParent,
        'description': description,
      };

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.parseResourceSummaryResponse(response.data);
    }
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceCreateAction && action.resourceId == parent) ||
      (action is ResourceMoveAction && action.resourceId == resourceId);
}
