import 'dart:typed_data';

import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_version_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_deleted_change.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/util/permissions.dart';

class ResourceUploadAction extends ResourceCreateAction with FileUploadApiAction {
  static const kActionName = 'resourceUpload';
  @override
  String get actionName => kActionName;

  @override
  String get method => 'PUT';

  @override
  String get endpoint => '/api/v1/fs/upload';

  @override
  MultipartFile createFile(Uint8List data) {
    var stream = ByteStream.fromBytes(data);
    return MultipartFile(
      'contents',
      stream,
      data.length,
      filename: resourceName,
      contentType: MediaType.parse(contentType),
    );
  }

  @override
  Map<String, String> get queryParameters => {
        'path': '$parent:$resourceName',
        'id': resourceId,
        'conflict': conflictResolution.toString(),
        'sha256': '', // TODO: compute and send
      };

  @override
  List<LocalChange> get localChanges => [
        CreateResourceChange(
          objectId: resourceId,
          parent: parent,
          localName: localName,
          dir: false,
          timestamp: timestamp,
          userPermission: userPermission,
        ),
        CreateResourceVersionChange(
          objectId: versionId,
          resourceId: resourceId,
          created: timestamp,
          size: size,
          mimeType: contentType,
          sha256: '<unknown>',
        ),
        if (deletedId != null)
          UpdateResourceDeletedChange(
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
        'size': size,
        'contentType': contentType,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'localName': localName,
        'deletedId': deletedId,
        'userPermission': userPermission,
        'versionId': versionId,
      };

  final int size;
  final String contentType;
  final DateTime timestamp;
  final String localName;
  final String? deletedId;
  final Permission userPermission;
  final String versionId;

  ResourceUploadAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    required super.conflictResolution,
    required this.size,
    required this.contentType,
    required this.timestamp,
    required this.localName,
    required this.deletedId,
    required this.userPermission,
    required this.versionId,
  });

  factory ResourceUploadAction.fromMap(Map<String, dynamic> map) {
    return ResourceUploadAction(
      resourceId: map['resourceId'],
      parent: map['parent'],
      resourceName: map['resourceName'],
      conflictResolution: map['conflictResolution'],
      size: map['size'],
      contentType: map['contentType'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      localName: map['localName'],
      deletedId: map['deletedId'],
      userPermission: map['userPermission'],
      versionId: map['versionId'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) => (action is ResourceCreateAction && action.resourceId == parent);
}
