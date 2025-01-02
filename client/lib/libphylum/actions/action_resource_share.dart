import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/util/permissions.dart';

import 'action_resource.dart';
import 'action_resource_create.dart';

class ResourceShareAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'resourceShare';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/share/$resourceId';

  @override
  bool get trackServerData => true;

  final String username;
  final int permission;
  final DateTime modified;
  final String description;

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
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'username': username,
        'permission': permission,
        'modified': modified.millisecondsSinceEpoch,
        'description': description,
      };

  @override
  String generateDescription() {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'username': username,
      'permission': permission,
    };
  }

  @override
  Future<void> applyOptimisticUpdate() async {
    final resource = await account.db.getResource(resourceId);
    final p = mergePermissions({}, resource?.permissions);
    if ((p[username] ?? 0) == permission) {
      return;
    }
    if (permission == 0) {
      p.remove(username);
    } else {
      p[username] = permission;
    }
    final serialized = p.isEmpty ? null : json.encode(p);
    account.db.updateResource(
      resourceId,
      (o) => o(
        permissions: Value(serialized),
        modified: Value(modified),
      ),
    );
  }

  @override
  Future<void> revertOptimisticUpdate() {
    final serverData = account.resourceRepository.getServerData(resourceId)!;
    return account.db.updateResource(
      resourceId,
      (o) => o(
        permissions: Value(serverData.permissions),
        modified: Value(serverData.modified),
      ),
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceShareAction && action.resourceId == resourceId && action.username == username);
}
