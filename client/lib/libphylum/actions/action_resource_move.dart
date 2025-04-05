import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/changes/mark_resource_modified_change.dart';
import 'package:phylum/libphylum/actions/changes/move_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/soft_delete_resource_change.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMoveAction extends ResourceBindAction with JsonApiAction {
  static const kActionName = 'resourceMove';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/move/$resourceId';

  @override
  Map<String, dynamic>? get requestBody => {
        // TODO: Do not send parent when only renaming
        'target': '$parent:$resourceName',
        'conflict': conflictResolution,
      };

  @override
  List<LocalChange> get localChanges => [
        MoveResourceChange(objectId: resourceId, parent: parent, name: localName, timestamp: modified),
        MarkResourceModifiedChange(objectId: parent, timestamp: modified),
        if (oldParent != null) MarkResourceModifiedChange(objectId: oldParent!, timestamp: modified),
        if (deletedId != null) SoftDeleteResourceChange(objectId: resourceId),
      ];

  @override
  final String description;

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'conflictResolution': conflictResolution,
        'description': description,
        'modified': modified.millisecondsSinceEpoch,
        'localName': localName,
        'oldParent': oldParent,
        'deletedId': deletedId,
      };

  final DateTime modified;
  final String localName;
  final String? oldParent;
  final String? deletedId;

  ResourceMoveAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.description,
    required this.modified,
    required this.oldParent,
    required this.localName,
    required this.deletedId,
  });

  static ResourceMoveAction fromMap(Map<String, dynamic> map) {
    return ResourceMoveAction(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      description: map['description'],
      modified: DateTime.fromMillisecondsSinceEpoch(map['modified']),
      localName: map['localName'],
      oldParent: map['oldParent'],
      deletedId: map['deletedId'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == resourceId) ||
      (action is ResourceCreateAction && action.resourceId == parent) ||
      (action is ResourceMoveAction && action.resourceId == resourceId);
}
