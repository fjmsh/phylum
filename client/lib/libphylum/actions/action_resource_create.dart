import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';

abstract class ResourceCreateAction extends ResourceBindAction {
  ResourceCreateAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
  });

  @override
  FutureOr<void> processResponse(ApiResponse response) async {
    if (response is PhylumApiSuccessResponse) {
      final resource = await account.resourceRepository.processResourceUpdateResponse(resourceId, response.data);
      final parsedId = resource.id.value;
      if (parsedId != resourceId) {
        revertOptimisticUpdate();
        account.actionQueue.updateActions((PhylumAction action) {
          if (action is ResourceAction && action.resourceId == resourceId && action != this) {
            action.updateResourceId(parsedId);
            return true;
          }
          return false;
        });
      }
    }
  }
}
