import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/util/permissions.dart';

class ResourceShareAction extends PhylumAction with JsonApiAction {
  static const actionName = 'resourceShare';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/share/$resourceId';

  final String resourceId;
  final String resourceName;
  final String username;
  final int permission;
  final DateTime modified;

  ResourceShareAction._(
      {required this.resourceId, required this.resourceName, required this.username, required this.permission, required this.modified});

  ResourceShareAction({
    required String resourceId,
    required String resourceName,
    required String username,
    required int permission,
  }) : this._(
          resourceId: resourceId,
          resourceName: resourceName,
          username: username,
          permission: permission,
          modified: DateTime.now(),
        );

  static ResourceShareAction fromMap(Map<String, dynamic> map) {
    return ResourceShareAction._(
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
      username: map['username'],
      permission: map['permission'],
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return 'Sharing $resourceName with $username';
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'username': username,
      'permission': permission,
    };
  }

  @override
  Future<void> initialize(PhylumAccount account) {
    return account.resourceRepository.trackServerData(resourceId);
  }

  @override
  Future<void> dispose(PhylumAccount account) {
    return account.resourceRepository.stopTrackingServerData(resourceId);
  }

  @override
  Future<void> applyOptimisticUpdate(PhylumAccount account) async {
    final resource = await account.resourceRepository.getResource(resourceId);
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
    account.resourceRepository.updateResource(
      resourceId,
      (o) => o(
        permissions: Value(serialized),
        modified: Value(modified),
      ),
    );
  }

  @override
  Future<void> revertOptimisticUpdate(PhylumAccount account) {
    final serverData = account.resourceRepository.getServerData(resourceId)!;
    return account.resourceRepository.updateResource(
      resourceId,
      (o) => o(
        permissions: Value(serverData.permissions),
        modified: Value(serverData.modified),
      ),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'resourceId': resourceId,
        'resourceName': resourceName,
        'username': username,
        'permission': permission,
        'modified': modified.millisecondsSinceEpoch,
      };

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
    }
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceShareAction && action.resourceId == resourceId && action.username == username);
}
