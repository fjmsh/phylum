import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_response.dart';

class ResourceDeleteAction extends ApiAction<PhylumApiResponse, PhylumApiErrorResponse, PhylumAccount> with JsonApiAction {
  static const actionName = 'resourceDelete';
  @override
  String get name => actionName;

  @override
  String get method => 'DELETE';

  @override
  String get endpoint => '/api/v1/resources/delete/$id';

  final String id;
  final String resourceName;

  ResourceDeleteAction._({
    required this.id,
    required this.resourceName,
  });

  ResourceDeleteAction({
    required Resource r,
  }) : this._(id: r.id, resourceName: r.name);

  static ResourceDeleteAction fromMap(Map<String, dynamic> map, dynamic data) {
    return ResourceDeleteAction._(
      id: map['id'],
      resourceName: map['resourceName'],
    );
  }

  @override
  String generateDescription(PhylumAccount account) {
    return "Deleting $resourceName";
  }

  @override
  Map<String, dynamic>? generateRequestBody() {
    return null;
  }

  @override
  FutureOr<void> applyOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.updateResource(id, (o) => o(deleted: const Value(true)));
  }

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {
    account.resourceRepository.updateResource(id, (o) => o(deleted: const Value(false)));
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'resourceName': resourceName,
      };
}
