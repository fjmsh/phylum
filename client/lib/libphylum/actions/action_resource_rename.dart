import 'dart:async';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_datastore.dart';

class ResourceRenameAction extends ApiAction<PhylumAccount> with JsonApiAction {
  static const actionName = 'resourceRename';
  @override
  String get name => actionName;

  @override
  String get method => 'POST';

  @override
  String get endpoint => '/api/v1/resources/rename/$id';

  @override
  get tag => resourceSummaryResponse;

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

  static ResourceRenameAction fromMap(Map<String, dynamic> map, dynamic data) {
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
}
