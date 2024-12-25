import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

import 'action_resource.dart';
import 'action_resource_create.dart';

class ResourceDeleteAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'resourceDelete';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'DELETE';

  @override
  String get endpoint => '/api/v1/fs/rm/$id';

  @override
  final String resourceId;
  final String resourceName;

  ResourceDeleteAction._({
    required this.resourceId,
    required this.resourceName,
  });

  ResourceDeleteAction({
    required Resource r,
  }) : this._(resourceId: r.id, resourceName: r.name);

  static ResourceDeleteAction fromMap(Map<String, dynamic> map) {
    return ResourceDeleteAction._(
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
    );
  }

  @override
  String generateDescription() {
    return "Deleting $resourceName";
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return null;
  }

  @override
  Future<void> applyOptimisticUpdate() {
    return account.resourceRepository.updateResource(resourceId, (o) => o(deleted: const Value(true)));
  }

  @override
  Future<void> revertOptimisticUpdate() {
    return account.resourceRepository.updateResource(resourceId, (o) => o(deleted: const Value(false)));
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'resourceName': resourceName,
      };

  @override
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == resourceId;
}
