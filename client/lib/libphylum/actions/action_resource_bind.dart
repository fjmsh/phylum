import 'action_resource.dart';

abstract class ResourceBindAction extends ResourceAction {
  String _parent;
  String get parent => _parent;

  String _resourceName;
  String get resourceName => _resourceName;

  ResourceBindAction({
    required super.resourceId,
    required String parent,
    required String resourceName,
  })  : _parent = parent,
        _resourceName = resourceName;

  Future<void> updateParent(String parent) {
    _parent = parent;
    return update();
  }

  Future<void> updateResourceName(String resourceName) {
    _resourceName = resourceName;
    return update();
  }
}
