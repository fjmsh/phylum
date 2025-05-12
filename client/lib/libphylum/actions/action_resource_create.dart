import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/responses/responses.dart';

abstract class ResourceCreateAction extends ResourceBindAction {
  ResourceCreateAction({
    required super.resourceId,
    required super.parent,
    required super.resourceName,
    super.conflictResolution,
  });

  @override
  FutureOr<void> processResponse(ApiResponse response) async {
    if (response is ResourceResponse) {
      if (response.resource.id != resourceId) {
        account.actionQueue.updateActions(
          (PhylumAction action) => action is ResourceAction && action.resourceId == resourceId,
          (action) => (action as ResourceAction).setResourceId(response.resource.id),
        );
      }
    }
  }
}
