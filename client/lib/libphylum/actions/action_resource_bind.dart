import 'package:phylum/libphylum/local_upload_errors.dart';

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
    return account.actionQueue.updateActions(
      (action) => action == this,
      (action) => (action as ResourceBindAction)._conflictResolution = conflictResolution,
    );
  }

  Future<void> updateParent(String parent) {
    return account.actionQueue.updateActions(
      (action) => action == this,
      (action) => (action as ResourceBindAction)._parent = parent,
    );
  }

  Future<void> updateResourceName(String resourceName) {
    return account.actionQueue.updateActions(
      (action) => action == this,
      (action) => (action as ResourceBindAction)._resourceName = resourceName,
    );
  }
}
