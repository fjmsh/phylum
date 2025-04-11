import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/mark_resource_deleted_change.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceCopyAction extends ResourceCreateAction with JsonApiAction {
  static const kActionName = 'resourceCopy';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/fs/copy/$srcId';

  @override
  Map<String, dynamic>? get requestBody => {
        'id': resourceId,
        'target': '$parent:$resourceName',
        'conflict': conflictResolution,
      };

  @override
  List<LocalChange> get localChanges => [
        CreateResourceChange(
          objectId: resourceId,
          parent: parent,
          localName: localName,
          timestamp: timestamp,
          contentLength: contentLength,
          contentType: contentType,
          contentSha256: contentSha256,
        ),
        if (deletedId != null)
          MarkResourceDeletedChange(
            objectId: deletedId!,
            timestamp: timestamp,
          ),
      ];

  @override
  final String description;

  @override
  Map<String, dynamic> get props => {
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
        'timestamp': timestamp.millisecondsSinceEpoch,
        'deletedId': deletedId,
      };

  final String srcId;
  final bool dir;
  final String localName;
  final String contentType;
  final int contentLength;
  final String contentSha256;
  final DateTime timestamp;
  final String? deletedId;

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
    required this.timestamp,
    required this.deletedId,
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
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      deletedId: map['deletedId'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) => action is ResourceCreateAction && action.resourceId == parent;
}
