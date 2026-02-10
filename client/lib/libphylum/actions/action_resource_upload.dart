import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_change.dart';
import 'package:phylum/libphylum/actions/changes/create_resource_version_change.dart';
import 'package:phylum/libphylum/actions/changes/update_resource_deleted_change.dart';
import 'package:phylum/libphylum/phylum_account.dart';
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
  ApiRequest<PhylumAccount> createApiRequest() {
    if (size < maxOneShotUploadSize) {
      return _OneShotUploadRequest(
        parent: parent,
        resourceName: resourceName,
        resourceId: resourceId,
        conflictResolution: conflictResolution,
        versionId: versionId,
        contentType: contentType,
      );
    }
    if (createRequired) {
      return _PartialStartRequest(uploadId: uploadId, size: size);
    }
    if (uploaded == null) {
      return _PartialQueryRequest(uploadId: uploadId);
    }
    if (uploaded == size) {
      return _PartialFinalizeRequest(
        uploadId: uploadId,
        parent: parent,
        resourceName: resourceName,
        resourceId: resourceId,
        conflictResolution: conflictResolution,
        versionId: versionId,
      );
    }
    return _PartialUploadRequest(uploadId: uploadId, uploaded: uploaded!);
  }

  @override
  Future<BaseRequest> createRequest(ApiClient api, {Blob? data}) => throw 'Cannot create upload request';

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) => throw 'Cannot parse upload response';

  @override
  ActionStatusUploading transformUploadingStatus(ActionStatusUploading status) {
    return ActionStatusUploading((uploaded ?? 0) + status.done, size);
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
      return true;
    }
    if (response is _PartialStartResponse) {
      uploaded = 0;
      createRequired = false;
      return false;
    }
    if (response is _PartialQueryResponse) {
      if (response.uploaded == -1 && response.size == -1) {
        createRequired = true;
      } else {
        uploaded = response.uploaded;
      }
      return false;
    }

    if (response is _PartialUploadResponse) {
      uploaded = response.uploaded;
      return false;
    }

    return false;
  }
}

class _OneShotUploadRequest extends ApiRequest<PhylumAccount> {
  final String parent;
  final String resourceName;
  final String resourceId;
  final int conflictResolution;
  final String versionId;
  final String contentType;

  _OneShotUploadRequest({
    required this.parent,
    required this.resourceName,
    required this.resourceId,
    required this.conflictResolution,
    required this.versionId,
    required this.contentType,
  });

  @override
  FutureOr<BaseRequest> createRequest(ApiClient<PhylumAccount> api, {Blob? data}) {
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
      ByteStream(data!.getStream()),
      data.length,
      filename: resourceName,
      contentType: MediaType.parse(contentType),
    ));
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, ResourceResponse.fromResponse);
  }
}

class _PartialStartRequest extends ApiRequest<PhylumAccount> {
  final String uploadId;
  final int size;

  _PartialStartRequest({required this.uploadId, required this.size});

  @override
  FutureOr<BaseRequest> createRequest(ApiClient<PhylumAccount> api, {Blob? data}) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/partial_uploads/start');
    return Request('POST', uriBuilder.build())
      ..bodyFields = {
        'id': uploadId,
        'size': size.toString(),
        // 'sha256': '', // TODO: compute and send
      };
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, _PartialStartResponse.fromResponse);
  }
}

class _PartialStartResponse extends PhylumApiSuccessResponse {
  final String id;

  _PartialStartResponse({required this.id});

  factory _PartialStartResponse.fromResponse(Map<String, dynamic> data) {
    final map = (data as Map).cast<String, dynamic>();
    return _PartialStartResponse(id: map['id']);
  }

  @override
  Future<void> process(PhylumAccount account) => SynchronousFuture(null);
}

class _PartialQueryRequest extends ApiRequest<PhylumAccount> {
  final String uploadId;

  _PartialQueryRequest({required this.uploadId});

  @override
  FutureOr<BaseRequest> createRequest(ApiClient<PhylumAccount> api, {Blob? data}) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/partial_uploads/query');
    uriBuilder.queryParameters = {'id': uploadId};
    return Request('GET', uriBuilder.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) async {
    final body = await response.bodyString();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final responseMap = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
      return _PartialQueryResponse.fromResponse(responseMap);
    }
    final errorResponse = PhylumApiErrorResponse.fromResponseBody(body);
    // Upon app start, the upload action will first try to query the status of the upload.
    // If the app exited wihtout getting a chance to first create the upload then this the expected response.
    if (errorResponse.code == "upload_not_found") {
      return _PartialQueryResponse(size: -1, uploaded: -1);
    }
    return errorResponse;
  }
}

class _PartialQueryResponse extends PhylumApiSuccessResponse {
  final int size;
  final int uploaded;

  _PartialQueryResponse({required this.size, required this.uploaded});

  factory _PartialQueryResponse.fromResponse(Map<String, dynamic> data) {
    final map = (data as Map).cast<String, dynamic>();
    return _PartialQueryResponse(size: map['size'], uploaded: map['uploaded']);
  }

  @override
  Future<void> process(PhylumAccount account) => SynchronousFuture(null);
}

class _PartialUploadRequest extends ApiRequest<PhylumAccount> {
  final String uploadId;
  final int uploaded;

  _PartialUploadRequest({required this.uploadId, required this.uploaded});

  @override
  FutureOr<BaseRequest> createRequest(ApiClient<PhylumAccount> api, {Blob? data}) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/partial_uploads/upload');
    uriBuilder.queryParameters = {
      'id': uploadId,
      'offset': uploaded.toString()
      // 'sha256': '', // TODO: compute and send
    };
    final request = MultipartRequest('PUT', uriBuilder.build());
    final length = chunkSize < data!.length - uploaded ? chunkSize : data.length - uploaded;
    request.files.add(MultipartFile(
      'contents',
      ByteStream(data.getStream(start: uploaded, end: uploaded + length)),
      length,
      filename: 'chunk',
      contentType: MediaType('application', 'octet-stream'),
    ));
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, _PartialUploadResponse.fromResponse);
  }
}

class _PartialUploadResponse extends PhylumApiSuccessResponse {
  final int uploaded;

  _PartialUploadResponse({required this.uploaded});

  factory _PartialUploadResponse.fromResponse(Map<String, dynamic> data) {
    final map = (data as Map).cast<String, dynamic>();
    return _PartialUploadResponse(uploaded: map['uploaded']);
  }

  @override
  Future<void> process(PhylumAccount account) => SynchronousFuture(null);
}

class _PartialFinalizeRequest extends ApiRequest<PhylumAccount> {
  final String uploadId;
  final String parent;
  final String resourceName;
  final String resourceId;
  final int conflictResolution;
  final String versionId;

  _PartialFinalizeRequest({
    required this.uploadId,
    required this.parent,
    required this.resourceName,
    required this.resourceId,
    required this.conflictResolution,
    required this.versionId,
  });

  @override
  FutureOr<BaseRequest> createRequest(ApiClient<PhylumAccount> api, {Blob? data}) {
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
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, ResourceResponse.fromResponse);
  }
}
