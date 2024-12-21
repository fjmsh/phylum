import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMkdirAction extends PhylumAction with JsonApiAction, ResourceCreateAction, ResourceBindAction {
  static const actionName = 'resourceMkdir';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mkdir/$resourceId';

  @override
  final String resourceId;
  @override
  final String parent;
  @override
  final String resourceName;

  ResourceMkdirAction({
    required this.resourceId,
    required this.parent,
    required this.resourceName,
  });

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
  FutureOr<void> processResponse(ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
    }
  }

  @override
  ResourceBindAction copyWithResourceName(String resourceName) {
    return ResourceMkdirAction(
      resourceId: resourceId,
      parent: parent,
      resourceName: resourceName,
    );
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceMkdirAction && action.resourceId == parent;
}
