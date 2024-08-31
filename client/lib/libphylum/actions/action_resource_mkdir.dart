import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';

class ResourceMkdirAction extends ApiAction<PhylumAccount> with JsonApiAction {
  static const actionName = 'resourceMkdir';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/v1/resources/mkdir/$id';

  @override
  dynamic get tag => 'resourceDetails';

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
    account.datastore.db.managers.resources.create((o) => o(
          dir: true,
          etag: "",
          size: 0,
          id: id,
          parent: Value(parent),
          modified: DateTime.now(),
          name: resourceName,
        ));
  }

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {
    account.datastore.db.managers.resources.filter((f) => f.id.equals(id)).delete();
  }

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'resourceName': resourceName,
        'parent': parent,
      };
}
