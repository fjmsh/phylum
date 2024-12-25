import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMkdirAction extends ResourceCreateAction with JsonApiAction {
  static const kActionName = 'resourceMkdir';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mkdir/$resourceId';

  @override
  final String resourceId;
  @override
  final String parent;
  String _resourceName;
  @override
  String get resourceName => _resourceName;

  ResourceMkdirAction({
    required this.resourceId,
    required this.parent,
    required String resourceName,
  }) : _resourceName = resourceName;

  static ResourceMkdirAction fromMap(Map<String, dynamic> map) {
    return ResourceMkdirAction(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
    );
  }

  @override
  String generateDescription() {
    return "Creating Directory $resourceName";
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'parent_id': parent,
      'name': resourceName,
    };
  }

  @override
  Future<void> applyOptimisticUpdate() {
    return account.resourceRepository.createResource(resourceId, true, parent, resourceName, '');
  }

  @override
  Future<void> revertOptimisticUpdate() {
    return account.resourceRepository.deleteResource(resourceId);
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'resourceName': resourceName,
        'parent': parent,
      };

  @override
  Future<void> updateResourceName(String resourceName) {
    _resourceName = resourceName;
    return update(revertOptimisticUpdate);
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceMkdirAction && action.resourceId == parent;
}
