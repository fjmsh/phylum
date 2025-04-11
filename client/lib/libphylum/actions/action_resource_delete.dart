import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_deleted_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_modified_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_trashed_change.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

import 'action_resource.dart';

class ResourceDeleteAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'resourceDelete';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'DELETE';

  @override
  String get endpoint => '/api/v1/fs/delete/$resourceId';

  @override
  List<LocalChange> get localChanges => [
        UpdateResourceDeletedChange(
          objectId: resourceId,
          timestamp: timestamp,
        ),
        UpdateResourceModifiedChange(
          objectId: resourceId,
          timestamp: timestamp,
        ),
        UpdateResourceTrashedChange(objectId: resourceId, add: true),
      ];

  @override
  String get description => "Deleting $resourceName";

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'resourceName': resourceName,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  final String resourceName;
  final DateTime timestamp;

  ResourceDeleteAction._({required super.resourceId, required this.resourceName, required this.timestamp});

  ResourceDeleteAction({
    required Resource r,
    required DateTime timestamp,
  }) : this._(
          resourceId: r.id,
          resourceName: r.name,
          timestamp: timestamp,
        );

  factory ResourceDeleteAction.fromMap(Map<String, dynamic> map) {
    return ResourceDeleteAction._(
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceAction && action.resourceId == resourceId;
}
