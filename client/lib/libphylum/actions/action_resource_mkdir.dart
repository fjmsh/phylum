import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/mark_resource_deleted_change.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceMkdirAction extends ResourceCreateAction with JsonApiAction {
  static const kActionName = 'resourceMkdir';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/mkdir/$resourceId';

  @override
  Map<String, dynamic>? get requestBody => {
        'parent_id': parent,
        'name': resourceName,
        'conflict': conflictResolution,
      };

  @override
  List<LocalChange> get localChanges => [
        CreateResourceChange(
          objectId: resourceId,
          parent: parent,
          localName: localName,
          timestamp: timestamp,
          contentLength: 0,
          contentType: '',
          contentSha256: '',
        ),
        if (deletedId != null)
          MarkResourceDeletedChange(
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
      };

  final DateTime timestamp;
  final String localName;
  final String? deletedId;

  ResourceMkdirAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.timestamp,
    required this.localName,
    required this.deletedId,
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
    );
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceMkdirAction && action.resourceId == parent;
}
