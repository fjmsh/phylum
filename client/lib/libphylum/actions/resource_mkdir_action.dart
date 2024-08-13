import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:uuid/uuid.dart';

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

  ResourceMkdirAction._({
    required this.id,
    required this.parent,
    required this.resourceName,
  });

  ResourceMkdirAction({
    required String parent,
    required String resourceName,
  }) : this._(id: (const Uuid()).v4(), parent: parent, resourceName: resourceName);

  static ResourceMkdirAction fromMap(Map<String, dynamic> map, dynamic data) {
    return ResourceMkdirAction._(
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
  FutureOr<void> applyOptimisticUpdate(PhylumAccount account) {}

  @override
  FutureOr<void> revertOptimisticUpdate(PhylumAccount account) {}

  @override
  Map<String, dynamic> toMap() => {
        'id': id,
        'resourceName': resourceName,
        'parent': parent,
      };
}
