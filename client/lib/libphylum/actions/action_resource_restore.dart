import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_deleted_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_modified_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_trashed_change.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

import 'action_resource.dart';

class ResourceRestoreAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'resourceRestore';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/trash/restore/$resourceId';

  @override
  List<LocalChange> get localChanges => [
    UpdateResourceDeletedChange(objectId: resourceId, timestamp: null),
    UpdateResourceModifiedChange(objectId: resourceId, timestamp: timestamp),
    UpdateResourceTrashedChange(objectId: resourceId, add: false),
  ];

  @override
  String get description => "Restoring $resourceName";

  @override
  Map<String, dynamic> get props => {
    'resourceId': resourceId,
    'resourceName': resourceName,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  final String resourceName;
  final DateTime timestamp;

  ResourceRestoreAction._({
    required super.resourceId,
    required this.resourceName,
    required this.timestamp,
  });

  ResourceRestoreAction({required Resource r, required DateTime timestamp})
    : this._(resourceId: r.id, resourceName: r.name, timestamp: timestamp);

  factory ResourceRestoreAction.fromMap(Map<String, dynamic> map) {
    return ResourceRestoreAction._(
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      action is ResourceAction && action.resourceId == resourceId;
}
