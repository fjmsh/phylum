import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_version_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_deleted_change.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/libphylum/util/uuid.dart';
import 'package:phylum/util/permissions.dart';

const maxOneShotUploadSize = 5 * 1024 * 1024;
const chunkSize = 2 * 1024 * 1024;

class ResourceUploadAction extends ResourceCreateAction {
  static const kActionName = 'resourceUpload';
  @override
  String get actionName => kActionName;

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
          sha256: '',
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
        'uploadId': uploadId,
      };

  final int size;
  final String contentType;
  final DateTime timestamp;
  final String localName;
  final String? deletedId;
  final Permission userPermission;
  final String versionId;
  final String uploadId;

  bool createRequired = false;
  int? uploaded;

  ResourceUploadAction._({
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
    required this.uploadId,
  });

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
  })  : uploadId = generateUuid(),
        uploaded = 0,
        createRequired = true;

  factory ResourceUploadAction.fromMap(Map<String, dynamic> map) {
    return ResourceUploadAction._(
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
      uploadId: map['uploadId'],
    );
  }

  @override
  bool dependsOn(PhylumAction action) => (action is ResourceCreateAction && action.resourceId == parent);

  @override
  Future<BaseRequest> createRequest(ApiClient api, {Blob? data}) async {
    if (size < maxOneShotUploadSize) {
      return createOneShotRequest(api, data!);
    }
    if (createRequired) {
      return createPartialStartRequest(api);
    }
    if (uploaded == null) {
      return createPartialQueryRequest(api);
    }
    if (uploaded == data!.length) {
      return createPartialFinalizeRequest(api);
    }
    return createPartialUploadRequest(api, data);
  }

  BaseRequest createOneShotRequest(ApiClient api, Blob data) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/upload');
    uriBuilder.queryParameters = {
      'path': '$parent:$resourceName',
      'id': resourceId,
      'conflict': conflictResolution.toString(),
      'version_id': versionId,
      // 'sha256': '', // TODO: compute and send
    };
    final request = MultipartRequest('PUT', uriBuilder.build());
    request.files.add(MultipartFile(
      'contents',
      ByteStream(data.getStream()),
      data.length,
      filename: resourceName,
      contentType: MediaType.parse(contentType),
    ));
    return request;
  }

  BaseRequest createPartialStartRequest(ApiClient api) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/partial_uploads/start');
    return Request('POST', uriBuilder.build())
      ..bodyFields = {
        'id': uploadId,
        'size': size.toString(),
        // 'sha256': '', // TODO: compute and send
      };
  }

  BaseRequest createPartialQueryRequest(ApiClient api) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/partial_uploads/query');
    uriBuilder.queryParameters = {'id': uploadId};
    return Request('GET', uriBuilder.build());
  }

  BaseRequest createPartialUploadRequest(ApiClient api, Blob data) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/partial_uploads/upload');
    final uploaded = this.uploaded!;
    uriBuilder.queryParameters = {
      'id': resourceId,
      'offset': uploaded.toString()
      // 'sha256': '', // TODO: compute and send
    };
    final request = MultipartRequest('PUT', uriBuilder.build());
    final length = chunkSize < data.length - uploaded ? chunkSize : data.length - uploaded;
    request.files.add(MultipartFile(
      'contents',
      ByteStream(data.getStream(start: uploaded, end: uploaded + length)),
      length,
      filename: resourceName,
      contentType: MediaType.parse(contentType),
    ));
    return request;
  }

  BaseRequest createPartialFinalizeRequest(ApiClient api) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/partial_uploads/finalize');
    return Request('POST', uriBuilder.build())
      ..bodyFields = {
        'upload_id': uploadId,
        'path': '$parent:$resourceName',
        'resource_id': resourceId,
        'version_id': versionId,
        'conflict': conflictResolution.toString(),
      };
  }

  @override
  bool processResponse(ApiResponse response) {
    if (response is ResourceResponse) {
      if (response.resource.id != resourceId) {
        account.actionQueue.updateActions(
          (PhylumAction action) => action is ResourceAction && action.resourceId == resourceId,
          (action) => (action as ResourceAction).setResourceId(response.resource.id),
        );
      }
    }
    return true;
  }
}
