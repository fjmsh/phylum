import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceDeleteAction extends PhylumAction with JsonApiAction {
  static const actionName = 'resourceDelete';
  @override
  String get name => actionName;

  @override
  String get method => 'DELETE';

  @override
  String get endpoint => '/api/v1/fs/rm/$id';

  final String id;
  final String resourceName;

  ResourceDeleteAction._({
    required this.id,
    required this.resourceName,
  });

  ResourceDeleteAction({
    required Resource r,
  }) : this._(id: r.id, resourceName: r.name);

  static ResourceDeleteAction fromMap(Map<String, dynamic> map) {
    return ResourceDeleteAction._(
      id: map['id'],
      resourceName: map['resourceName'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return "Deleting $resourceName";
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return null;
  }

  @override
  Future<void> applyOptimisticUpdate(PhylumAccount account) {
    return account.resourceRepository.updateResource(id, (o) => o(deleted: const Value(true)));
  }

  @override
  Future<void> revertOptimisticUpdate(PhylumAccount account) {
    return account.resourceRepository.updateResource(id, (o) => o(deleted: const Value(false)));
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'resourceName': resourceName,
      };

  @override
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == id;
}
