import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/changes/soft_delete_resource_change.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

import 'action_resource.dart';
import 'action_resource_create.dart';

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
        SoftDeleteResourceChange(objectId: resourceId),
      ];

  @override
  String get description => "Deleting $resourceName";

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'resourceName': resourceName,
      };

  final String resourceName;

  ResourceDeleteAction._({
    required super.resourceId,
    required this.resourceName,
  });

  ResourceDeleteAction({
    required Resource r,
  }) : this._(resourceId: r.id, resourceName: r.name);

  factory ResourceDeleteAction.fromMap(Map<String, dynamic> map) {
    return ResourceDeleteAction._(
      resourceId: map['resourceId'],
      resourceName: map['resourceName'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == resourceId;
}
