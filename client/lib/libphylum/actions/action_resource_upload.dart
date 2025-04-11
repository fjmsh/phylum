import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/mark_resource_deleted_change.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

class ResourceUploadAction extends ResourceCreateAction with FileUploadApiAction {
  static const kActionName = 'resourceUpload';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'PUT';

  @override
  String get endpoint => '/api/v1/fs/upload/$resourceId';

  @override
  Future<MultipartFile> get file =>
      MultipartFile.fromPath('contents', path, filename: resourceName, contentType: MediaType.parse(contentType));

  @override
  Map<String, String> get fields => {
        'parent_id': parent,
        'name': resourceName,
        'conflict': conflictResolution.toString(),
      };

  @override
  List<LocalChange> get localChanges => [
        CreateResourceChange(
          objectId: resourceId,
          parent: parent,
          localName: localName,
          timestamp: timestamp,
          contentLength: size,
          contentType: contentType,
          contentSha256: '<unknown>',
        ),
        if (deletedId != null)
          MarkResourceDeletedChange(
            objectId: deletedId!,
            timestamp: timestamp,
          ),
      ];

  @override
  String get description => "Uploading $resourceName";

  @override
  Map<String, dynamic> get props => {
        'resourceId': resourceId,
        'parent': parent,
        'resourceName': resourceName,
        'conflictResolution': conflictResolution,
        'path': path,
        'size': size,
        'contentType': contentType,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'localName': localName,
        'deletedId': deletedId,
      };

  final String path;
  final int size;
  final String contentType;
  final DateTime timestamp;
  final String localName;
  final String? deletedId;

  ResourceUploadAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.path,
    required this.size,
    required this.contentType,
    required this.timestamp,
    required this.localName,
    required this.deletedId,
  });

  factory ResourceUploadAction.fromMap(Map<String, dynamic> map) {
    return ResourceUploadAction(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      path: map['path'],
      size: map['size'],
      contentType: map['contentType'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      localName: map['localName'],
      deletedId: map['deletedId'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) => (action is ResourceCreateAction && action.resourceId == parent);
}
