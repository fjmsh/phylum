import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceCopyAction extends ResourceCreateAction with JsonApiAction {
  static const kActionName = 'resourceCopy';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/cp/$srcId';

  final String srcId;
  final String description;
  final bool dir;
  final String localName;
  final String contentType;
  final int contentLength;
  final String contentSha256;

  ResourceCopyAction({
    required this.srcId,
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.dir,
    required this.localName,
    required this.contentType,
    required this.contentLength,
    required this.contentSha256,
    required this.description,
  });

  factory ResourceCopyAction.fromMap(Map<String, dynamic> map) {
    return ResourceCopyAction(
      srcId: map['srcId'],
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      dir: map['dir'],
      localName: map['localName'],
      contentType: map['contentType'],
      contentLength: map['contentLength'],
      contentSha256: map['contentSha256'],
      description: map['description'],
    );
  }

  @override
  Map<String, dynamic> toMap() => {
        'srcId': srcId,
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'conflictResolution': conflictResolution,
        'dir': dir,
        'localName': localName,
        'contentType': contentType,
        'contentLength': contentLength,
        'contentSha256': contentSha256,
        'description': description,
      };

  @override
  String generateDescription() {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'id': resourceId,
      'target': '$parent:$resourceName',
      'conflict': conflictResolution,
    };
  }

  @override
  Future<void> applyOptimisticUpdate() async {
    await account.db.createResource(resourceId, parent, localName, dir);
    if (!dir) {
      await account.db.updateResource(
        resourceId,
        (o) => o(
          contentType: Value(contentType),
          contentLength: Value(contentLength),
          contentSha256: Value(contentSha256),
        ),
      );
    }
  }

  @override
  Future<void> revertOptimisticUpdate() {
    return account.db.deleteResource(resourceId);
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == parent;
}
