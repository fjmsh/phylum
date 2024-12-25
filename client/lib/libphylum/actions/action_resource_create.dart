import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

abstract class ResourceCreateAction extends ResourceBindAction {
  @override
  FutureOr<void> processResponse(ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      final resource = await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
      if (resource.id.value != resourceId) {
        revertOptimisticUpdate();
      }
    }
  }
}
