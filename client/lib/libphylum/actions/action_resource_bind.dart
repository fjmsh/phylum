import 'action_resource.dart';

abstract class ResourceBindAction extends ResourceAction {
  String get parent;
  String get resourceName;

  Future<void> updateResourceName(String resourceName);
}
