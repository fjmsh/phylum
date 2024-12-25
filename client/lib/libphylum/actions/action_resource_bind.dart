import 'action_resource.dart';

typedef ResourceBindConflictResolution = int;
const ResourceBindConflictResolution resourceBindConflictResolutionNone = 0;
const ResourceBindConflictResolution resourceBindConflictResolutionOverwrite = 1;
const ResourceBindConflictResolution resourceBindConflictResolutionRename = 2;

abstract class ResourceBindAction extends ResourceAction {
  ResourceBindConflictResolution _conflictResolution;
  ResourceBindConflictResolution get conflictResolution => _conflictResolution;

  String _parent;
  String get parent => _parent;

  String _resourceName;
  String get resourceName => _resourceName;

  ResourceBindAction({
    required super.resourceId,
    required String parent,
    required String resourceName,
    ResourceBindConflictResolution conflictResolution = resourceBindConflictResolutionNone,
  })  : _parent = parent,
        _resourceName = resourceName,
        _conflictResolution = conflictResolution;

  Future<void> updateConflictResolution(ResourceBindConflictResolution conflictResolution) {
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
