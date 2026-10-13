import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_modified_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_version_deleted_change.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

import 'action_resource.dart';

class ResourceVersionDeleteAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'resourceVersionDelete';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/delete_version';

  @override
  Map<String, dynamic>? get requestBody => {
    'path': '$resourceId:',
    'version_id': versionId,
  };

  @override
  List<LocalChange> get localChanges => [
    UpdateResourceVersionDeletedChange(objectId: versionId),
    UpdateResourceModifiedChange(objectId: resourceId, timestamp: timestamp),
  ];

  @override
  String get description =>
      "Deleting version ${versionId.substring(0, 12)} of $resourceName";

  @override
  Map<String, dynamic> get props => {
    'resourceId': resourceId,
    'versionId': versionId,
    'resourceName': resourceName,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  final String versionId;
  final String resourceName;
  final DateTime timestamp;

  ResourceVersionDeleteAction._({
    required super.resourceId,
    required this.timestamp,
    required this.resourceName,
    required this.versionId,
  });

  ResourceVersionDeleteAction({required Resource r, required String versionId})
    : this._(
        resourceId: r.id,
        versionId: versionId,
        resourceName: r.name,
        timestamp: DateTime.now(),
      );

  factory ResourceVersionDeleteAction.fromMap(Map<String, dynamic> map) {
    return ResourceVersionDeleteAction._(
      resourceId: map['resourceId'],
      versionId: map['versionId'],
      resourceName: map['resourceName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  @override
  bool dependsOn(PhylumAction action) =>
      action is ResourceAction && action.resourceId == resourceId;
}
