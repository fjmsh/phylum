import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/changes/delete_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_deleted_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_modified_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_trashed_change.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

import 'action_resource.dart';

class ResourceDeleteAction extends ResourceAction with JsonApiAction {
  static const kActionName = 'resourceDelete';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/delete';

  @override
  Map<String, dynamic>? get requestBody => {
        'path': '$resourceId:',
        'permanent': permanent,
      };

  @override
  List<LocalChange> get localChanges => permanent
      ? [
          DeleteResourceChange(objectId: resourceId),
        ]
      : [
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
        'permanent': permanent,
      };

  final String resourceName;
  final DateTime timestamp;
  final bool permanent;

  ResourceDeleteAction._({
    required super.resourceId,
    required this.resourceName,
    required this.timestamp,
    required this.permanent,
  });

  ResourceDeleteAction({
    required Resource r,
    required DateTime timestamp,
    bool permanent = false,
  }) : this._(
          resourceId: r.id,
          resourceName: r.name,
          timestamp: timestamp,
          permanent: permanent,
        );

  factory ResourceDeleteAction.fromMap(Map<String, dynamic> map) {
    return ResourceDeleteAction._(
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      permanent: map['permanent'] ?? false,
    );
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceAction && action.resourceId == resourceId;

  @override
  ResponseParser get parseResponse =>
      permanent ? (_, response) => parseJsonMapResponse(response, EmptyResponse.fromResponse) : super.parseResponse;
}
