import 'package:phylum/libphylum/name_conflict.dart';

import 'action_resource.dart';

abstract class ResourceBindAction extends ResourceAction {
  NameConflictResolution _conflictResolution;
  NameConflictResolution get conflictResolution => _conflictResolution;

  String _parent;
  String get parent => _parent;

  String _resourceName;
  String get resourceName => _resourceName;

  ResourceBindAction({
    required super.resourceId,
    required String parent,
    required String resourceName,
    NameConflictResolution conflictResolution = nameConflictError,
  })  : _parent = parent,
        _resourceName = resourceName,
        _conflictResolution = conflictResolution;

  Future<void> updateConflictResolution(NameConflictResolution conflictResolution) {
    _conflictResolution = conflictResolution;
    return update();
  }

  Future<void> updateParent(String parent) {
    _parent = parent;
    return update();
  }

  Future<void> updateResourceName(String resourceName) {
    _resourceName = resourceName;
    return update();
  }
}
