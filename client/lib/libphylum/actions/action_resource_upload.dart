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

sealed class _UploadState {
  const _UploadState();
}

class _UploadStateUnknown extends _UploadState {
  const _UploadStateUnknown();
}

class _UploadNeedsCreation extends _UploadState {
  const _UploadNeedsCreation();
}

class _UploadUploading extends _UploadState {
  final int uploaded;

  const _UploadUploading({required this.uploaded});
}

class _UploadFinalized extends _UploadState {
  const _UploadFinalized();
}

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
      UpdateResourceDeletedChange(objectId: deletedId!, timestamp: timestamp),
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

  _UploadState _state = const _UploadStateUnknown();

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
  }) : uploadId = generateUuid(),
       _state = const _UploadNeedsCreation();

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
  bool dependsOn(PhylumAction action) =>
      (action is ResourceCreateAction && action.resourceId == parent);

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
    final state = _state;
    switch (state) {
      case _UploadStateUnknown():
        return _UploadQueryRequest(uploadId: uploadId);
      case _UploadNeedsCreation():
        return _UploadStartRequest(uploadId: uploadId, size: size);
      case _UploadUploading(uploaded: int uploaded):
        if (uploaded != size) {
          return _PartialUploadRequest(uploadId: uploadId, uploaded: uploaded);
        }
        return _PartialFinalizeRequest(
          uploadId: uploadId,
          parent: parent,
          resourceName: resourceName,
          resourceId: resourceId,
          conflictResolution: conflictResolution,
          versionId: versionId,
        );
      case _UploadFinalized():
        return _PartialFinalizeRequest(
          uploadId: uploadId,
          parent: parent,
          resourceName: resourceName,
          resourceId: resourceId,
          conflictResolution: conflictResolution,
          versionId: versionId,
        );
    }
  }

  @override
  Future<BaseRequest> createRequest(ApiClient api, {Blob? data}) =>
      throw 'Cannot create upload request';

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) =>
      throw 'Cannot parse upload response';

  @override
  ActionStatusUploading transformUploadingStatus(ActionStatusUploading status) {
    final state = _state;
    final uploaded = (state is _UploadUploading) ? state.uploaded : 0;
    return ActionStatusUploading(uploaded + status.done, size);
  }

  @override
  bool processResponse(ApiResponse response) {
    if (response is ResourceResponse) {
      if (response.resource.id != resourceId) {
        account.actionQueue.updateActions(
          (PhylumAction action) =>
              action is ResourceAction && action.resourceId == resourceId,
          (action) =>
              (action as ResourceAction).setResourceId(response.resource.id),
        );
      }
      return true;
    }
    if (response is _StatusResponse) {
      _state = response.state;
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
  FutureOr<BaseRequest> createRequest(
    ApiClient<PhylumAccount> api, {
    Blob? data,
  }) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/uploads/single');
    final request = MultipartRequest('PUT', uriBuilder.build());

    request
      ..fields['path'] = ':$parent/$resourceName'
      ..fields['id'] = resourceId
      ..fields['conflict'] = conflictResolution.toString()
      ..fields['version_id'] = versionId;
    request.files.add(
      MultipartFile(
        'contents',
        ByteStream(data!.getStream()),
        data.length,
        filename: resourceName,
        contentType: MediaType.parse(contentType),
      ),
    );
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) {
    return parseJsonMapResponse(response, ResourceResponse.fromResponse);
  }
}

class _UploadStartRequest extends ApiRequest<PhylumAccount> {
  final String uploadId;
  final int size;

  _UploadStartRequest({required this.uploadId, required this.size});

  @override
  FutureOr<BaseRequest> createRequest(
    ApiClient<PhylumAccount> api, {
    Blob? data,
  }) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/uploads/start');
    return Request('POST', uriBuilder.build())
      ..bodyFields = {
        'id': uploadId,
        'size': size.toString(),
        // 'sha256': '', // TODO: compute and send
      };
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) =>
      parsePartialUploadResponse(response);
}

class _UploadQueryRequest extends ApiRequest<PhylumAccount> {
  final String uploadId;

  _UploadQueryRequest({required this.uploadId});

  @override
  FutureOr<BaseRequest> createRequest(
    ApiClient<PhylumAccount> api, {
    Blob? data,
  }) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/uploads/query');
    uriBuilder.queryParameters = {'id': uploadId};
    return Request('GET', uriBuilder.build());
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) =>
      parsePartialUploadResponse(response);
}

Future<ApiResponse<PhylumAccount>> parsePartialUploadResponse(
  StreamedResponse response,
) async {
  final body = await response.bodyString();
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final responseMap = (jsonDecode(body) as Map<String, dynamic>?) ?? const {};
    return _StatusResponse.fromResponse(responseMap);
  }
  final errorResponse = PhylumApiErrorResponse.fromResponseBody(body);
  // Upon app start, the upload action will first try to query the status of the upload.
  // If the app exited wihtout getting a chance to first create the upload then this the expected response.
  if (errorResponse.code == "upload_not_found") {
    return _StatusResponse(state: _UploadNeedsCreation());
  }
  if (errorResponse.code == "upload_finalized") {
    return _StatusResponse(state: _UploadFinalized());
  }
  return errorResponse;
}

class _StatusResponse extends PhylumApiSuccessResponse {
  final _UploadState state;

  _StatusResponse({required this.state});

  factory _StatusResponse.fromResponse(Map<String, dynamic> data) {
    final map = (data as Map).cast<String, dynamic>();
    return _StatusResponse(
      state: _UploadUploading(uploaded: map['uploaded'] ?? 0),
    );
  }

  @override
  Future<void> process(PhylumAccount account) => SynchronousFuture(null);
}

class _PartialUploadRequest extends ApiRequest<PhylumAccount> {
  final String uploadId;
  final int uploaded;

  _PartialUploadRequest({required this.uploadId, required this.uploaded});

  @override
  FutureOr<BaseRequest> createRequest(
    ApiClient<PhylumAccount> api, {
    Blob? data,
  }) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/uploads/chunk');
    uriBuilder.queryParameters = {
      'id': uploadId,
      'offset': uploaded.toString(),
      // 'sha256': '', // TODO: compute and send
    };
    final request = MultipartRequest('PUT', uriBuilder.build());
    final length = chunkSize < data!.length - uploaded
        ? chunkSize
        : data.length - uploaded;
    request.files.add(
      MultipartFile(
        'contents',
        ByteStream(data.getStream(start: uploaded, end: uploaded + length)),
        length,
        filename: 'chunk',
        contentType: MediaType('application', 'octet-stream'),
      ),
    );
    return request;
  }

  @override
  Future<ApiResponse<PhylumAccount>> parseResponse(StreamedResponse response) =>
      parsePartialUploadResponse(response);
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
  FutureOr<BaseRequest> createRequest(
    ApiClient<PhylumAccount> api, {
    Blob? data,
  }) {
    final uriBuilder = api.createUriBuilder('/api/v1/fs/uploads/finalize');
    return Request('POST', uriBuilder.build())
      ..bodyFields = {
        'upload_id': uploadId,
        'path': ':$parent/$resourceName',
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
