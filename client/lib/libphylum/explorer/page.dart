import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/permissions.dart';

sealed class ExplorerPage {
  const ExplorerPage();

  Future<bool> refresh(PhylumAccount account);

  Stream<Resource?> watchResource(PhylumAccount account);

  Stream<List<Resource>> watchChildren(PhylumAccount account);

  Stream<List<ParentsResult>> watchParents(PhylumAccount account);
}

class ExplorerPageFolder extends ExplorerPage {
  final String folderId;

  ExplorerPageFolder({required this.folderId});

  @override
  Future<bool> refresh(PhylumAccount account) =>
      account.resourceRepository.requestResource(folderId).then((result) => result is ApiSuccessResponse);

  @override
  Stream<Resource?> watchResource(PhylumAccount account) => account.db.watchResource(folderId);

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) => account.db.watchChildren(folderId);

  @override
  Stream<List<ParentsResult>> watchParents(PhylumAccount account) {
    return account.db.watchParents(folderId).map((p) {
      if (p.isEmpty) {
        p = [
          ParentsResult(id: folderId, name: 'Loading...'),
        ];
      }
      int index = p.indexWhere((r) => r.id == account.userHome);
      if (index >= 0) {
        p[index] = ParentsResult(id: account.userHome, name: 'My Files');
      } else {
        index = p.lastIndexWhere((r) =>
            r.permissions != null &&
            ((jsonDecode(r.permissions!) as Map).cast<String, Permission>()[account.userName] ?? 0) & permissionRead !=
                0);
        if (index < 0) {
          index = 0;
        }
      }
      return ListSlice(p, 0, index + 1);
    });
  }

  @override
  String toString() => 'ExplorerPageFolder($folderId)';

  @override
  bool operator ==(Object other) {
    return other is ExplorerPageFolder && other.folderId == folderId;
  }

  @override
  int get hashCode => folderId.hashCode;
}

class ExplorerPageRecents extends ExplorerPage {
  const ExplorerPageRecents();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return Future.value(true);
  }

  @override
  Stream<Resource?> watchResource(PhylumAccount account) {
    return Stream.fromIterable([null]);
  }

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) {
    return account.db.selectRecents().watch();
  }

  @override
  Stream<List<ParentsResult>> watchParents(PhylumAccount account) {
    return Stream.fromIterable([
      [],
    ]);
  }

  @override
  String toString() {
    return 'ExplorerPageRecents';
  }
}

class ExplorerPageTrash extends ExplorerPage {
  const ExplorerPageTrash();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.resourceRepository.requestDeletedResources().then((result) => result is ApiSuccessResponse);
  }

  @override
  Stream<Resource?> watchResource(PhylumAccount account) {
    return Stream.fromIterable([null]);
  }

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) {
    return account.db.selectDeleted().watch();
  }

  @override
  Stream<List<ParentsResult>> watchParents(PhylumAccount account) {
    return Stream.fromIterable([
      [],
    ]);
  }

  @override
  String toString() {
    return 'ExplorerPageTrash';
  }
}

class ExplorerPageShared extends ExplorerPage {
  const ExplorerPageShared();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.sharedResourcesRepository.refresh().then((result) => result is ApiSuccessResponse);
  }

  @override
  Stream<Resource?> watchResource(PhylumAccount account) {
    return Stream.fromIterable([null]);
  }

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) {
    return account.db.selectShared().watch();
  }

  @override
  Stream<List<ParentsResult>> watchParents(PhylumAccount account) {
    return Stream.fromIterable([
      [],
    ]);
  }

  @override
  String toString() {
    return 'ExplorerPageShared';
  }
}
