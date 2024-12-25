import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

abstract class ResourceAction extends PhylumAction {
  String _resourceId;
  String get resourceId => _resourceId;

  ResourceAction({required String resourceId}) : _resourceId = resourceId;

  void updateResourceId(String resourceId) {
    _resourceId = resourceId;
  }

  @override
  FutureOr<void> processResponse(ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
    }
  }
}
