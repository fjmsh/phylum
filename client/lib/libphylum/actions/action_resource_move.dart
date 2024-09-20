import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_response.dart';

class ResourceMoveAction extends ApiAction<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> with JsonApiAction {
  static const actionName = 'resourceMove';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/resources/move/$id';

  final String id;
  final String parent;
  final String? oldParent;
  final String description;

  ResourceMoveAction._({required this.id, required this.parent, required this.oldParent, required this.description});

  ResourceMoveAction({
    required Resource r,
    required Resource parent,
  }) : this._(id: r.id, parent: parent.id, oldParent: r.parent, description: 'Moving ${r.name} to ${parent.name}');

  static ResourceMoveAction fromMap(Map<String, dynamic> map, dynamic data) {
    return ResourceMoveAction._(id: map['id'], parent: map['parent'], oldParent: map['oldParent'], description: map['description']);
  }

  @override
  String generateDescription(PhylumAccount account) {
    return description;
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'parent_id': parent,
    };
  }

  @override
  FutureOr<void> applyOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.updateResource(id, (o) => o(parent: Value(parent)));
  }

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.updateResource(id, (o) => o(parent: Value(oldParent)));
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'parent': parent,
        'oldParent': oldParent,
        'description': description,
      };

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse<PhylumApiResponse, PhylumApiErrorResponse> response) async {
    if (response is ApiSuccessResponse<PhylumApiResponse, PhylumApiErrorResponse>) {
      await account.resourceRepository.parseResourceSummaryResponse(response.result);
    }
  }
}
