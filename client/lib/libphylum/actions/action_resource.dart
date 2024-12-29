import 'dart:async';

import 'package:meta/meta.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

abstract class ResourceAction extends PhylumAction {
  @visibleForOverriding
  bool get trackServerData => false;
  String _resourceId;
  String get resourceId => _resourceId;

  ResourceAction({required String resourceId}) : _resourceId = resourceId;

  @override
  @mustCallSuper
  Future<void> initialize() {
    if (trackServerData) {
      return account.resourceRepository.trackServerData(resourceId);
    }
    return Future.value(null);
  }

  @override
  @mustCallSuper
  Future<void> dispose() {
    if (trackServerData) {
      return account.resourceRepository.stopTrackingServerData(resourceId);
    }
    return Future.value(null);
  }

  void updateResourceId(String resourceId) {
    account.resourceRepository.stopTrackingServerData(_resourceId);
    _resourceId = resourceId;
    account.resourceRepository.trackServerData(_resourceId);
  }

  @override
  FutureOr<void> processResponse(ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
    }
  }
}
