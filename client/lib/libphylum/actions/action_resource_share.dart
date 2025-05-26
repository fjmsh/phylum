import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_user_invite.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_permissions_change.dart';
import 'package:phylum/libphylum/db/db.dart';
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
        'email': userEmail,
        'permission': permission,
      };

  @override
  List<LocalChange> get localChanges => [
        UpdateResourcePermissionsChange(
          objectId: resourceId,
          userId: userId.toString(),
          permission: permission,
          timestamp: modified,
        ),
      ];

  @override
  final String description;

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'userId': userId,
        'userEmail': userEmail,
        'permission': permission,
        'modified': modified.millisecondsSinceEpoch,
        'description': description,
      };

  int _userId;
  int get userId => _userId;
  final String userEmail;
  final int permission;
  final DateTime modified;

  ResourceShareAction._({
    required super.resourceId,
    required int userId,
    required this.userEmail,
    required this.permission,
    required this.modified,
    required this.description,
  }) : _userId = userId;

  ResourceShareAction({
    required String resourceId,
    required String resourceName,
    required User user,
    required int permission,
  }) : this._(
          resourceId: resourceId,
          userId: user.id,
          userEmail: user.email,
          permission: permission,
          modified: DateTime.now(),
          description: 'Sharing $resourceName with ${user.displayName}',
        );

  static ResourceShareAction fromMap(Map<String, dynamic> map) {
    return ResourceShareAction._(
      resourceId: map['resourceId'],
      userId: map['userId'],
      userEmail: map['userEmail'],
      permission: map['permission'],
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
      description: map['description'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceShareAction && action.resourceId == resourceId && action.userEmail == userEmail) ||
      (action is UserInviteAction && action.localId == userId);
}
