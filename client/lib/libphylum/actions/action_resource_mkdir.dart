import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_response.dart';

class ResourceMkdirAction extends ApiAction<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> with JsonApiAction {
  static const actionName = 'resourceMkdir';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/resources/mkdir/$id';

  final String id;
  final String parent;
  final String resourceName;

  ResourceMkdirAction({
    required this.id,
    required this.parent,
    required this.resourceName,
  });

  static ResourceMkdirAction fromMap(Map<String, dynamic> map, dynamic data) {
    return ResourceMkdirAction(
      id: map['id'],
      parent: map['parent'],
      resourceName: map['resourceName'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return "Creating Directory $resourceName";
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'parent_id': parent,
      'name': resourceName,
    };
  }

  @override
  FutureOr<void> applyOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.createResource(id, true, parent, resourceName, '');
  }

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.deleteResource(id);
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'resourceName': resourceName,
        'parent': parent,
      };

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse<PhylumApiResponse, PhylumApiErrorResponse> response) async {
    if (response is ApiSuccessResponse<PhylumApiResponse, PhylumApiErrorResponse>) {
      await account.resourceRepository.parseResourceSummaryResponse(response.result);
    }
  }
}
