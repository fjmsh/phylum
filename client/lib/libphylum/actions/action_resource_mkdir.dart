import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_deleted_change.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/util/permissions.dart';

class ResourceMkdirAction extends ResourceCreateAction with JsonApiAction {
  static const kActionName = 'resourceMkdir';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mkdir';

  @override
  Map<String, dynamic>? get requestBody => {
        'path': '$parent:$resourceName',
        'id': resourceId,
        'conflict': conflictResolution,
      };

  @override
  List<LocalChange> get localChanges => [
        CreateResourceChange(
          objectId: resourceId,
          parent: parent,
          localName: localName,
          dir: true,
          timestamp: timestamp,
          contentLength: 0,
          contentType: '',
          contentSha256: '',
          userPermission: userPermission,
        ),
        if (deletedId != null)
          UpdateResourceDeletedChange(
            objectId: resourceId,
            timestamp: timestamp,
          ),
      ];

  @override
  String get description => "Creating Directory $resourceName";

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'resourceName': resourceName,
        'parent': parent,
        'conflictResolution': conflictResolution,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'localName': localName,
        'deletedId': deletedId,
        'userPermission': userPermission,
      };

  final DateTime timestamp;
  final String localName;
  final String? deletedId;
  final Permission userPermission;

  ResourceMkdirAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.timestamp,
    required this.localName,
    required this.deletedId,
    required this.userPermission,
  });

  static ResourceMkdirAction fromMap(Map<String, dynamic> map) {
    return ResourceMkdirAction(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      localName: map['localName'],
      deletedId: map['deletedId'],
      userPermission: map['userPermission'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceMkdirAction && action.resourceId == parent;
}
