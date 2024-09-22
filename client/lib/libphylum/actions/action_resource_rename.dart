import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/actions/action_resource_create.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_response.dart';

class ResourceRenameAction extends ApiAction<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> with JsonApiAction {
  static const actionName = 'resourceRename';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/resources/rename/$id';

  final String id;
  final String newName;
  final String oldName;

  ResourceRenameAction._({
    required this.id,
    required this.newName,
    required this.oldName,
  });

  ResourceRenameAction({
    required Resource r,
    required String name,
  }) : this._(id: r.id, newName: name, oldName: r.name);

  static ResourceRenameAction fromMap(Map<String, dynamic> map) {
    return ResourceRenameAction._(
      id: map['id'],
      newName: map['newName'],
      oldName: map['oldName'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return "Renaming $oldName to $newName";
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return {
      'name': newName,
    };
  }

  @override
  FutureOr<void> applyOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.updateResource(id, (o) => o(name: Value(newName)));
  }

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.updateResource(id, (o) => o(name: Value(oldName)));
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'newName': newName,
        'oldName': oldName,
      };

  @override
  FutureOr<void> processResponse(PhylumAccount account, ApiResponse<PhylumApiResponse, PhylumApiErrorResponse> response) async {
    if (response is ApiSuccessResponse<PhylumApiResponse, PhylumApiErrorResponse>) {
      await account.resourceRepository.parseResourceSummaryResponse(response.result);
    }
  }

  @override
  bool dependsOn(ApiAction<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> action) =>
      (action is ResourceCreateAction && action.resourceId == id);
}
