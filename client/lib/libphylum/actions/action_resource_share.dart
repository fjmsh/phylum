import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_permissions_change.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

import 'action_resource.dart';
import 'action_resource_create.dart';

class ResourceShareAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'resourceShare';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/share';

  @override
  Map<String, dynamic>? get requestBody => {
        'path': '$resourceId:',
        'username': username,
        'permission': permission,
      };

  @override
  List<LocalChange> get localChanges => [
        UpdateResourcePermissionsChange(
          objectId: resourceId,
          username: username,
          permission: permission,
          timestamp: modified,
        ),
      ];

  @override
  final String description;

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'username': username,
        'permission': permission,
        'modified': modified.millisecondsSinceEpoch,
        'description': description,
      };

  final String username;
  final int permission;
  final DateTime modified;

  ResourceShareAction._({
    required super.resourceId,
    required this.username,
    required this.permission,
    required this.modified,
    required this.description,
  });

  ResourceShareAction({
    required String resourceId,
    required String resourceName,
    required String username,
    required int permission,
  }) : this._(
          resourceId: resourceId,
          username: username,
          permission: permission,
          modified: DateTime.now(),
          description: 'Sharing $resourceName with $username',
        );

  static ResourceShareAction fromMap(Map<String, dynamic> map) {
    return ResourceShareAction._(
      resourceId: map['resourceId'],
      username: map['username'],
      permission: map['permission'],
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
      description: map['description'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceShareAction && action.resourceId == resourceId && action.username == username);
}
