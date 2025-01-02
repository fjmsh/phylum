import 'package:flutter/foundation.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';

sealed class ExplorerPage {
  const ExplorerPage();

  Future<bool> refresh(PhylumAccount account);

  Stream<Resource?> watchResource(PhylumAccount account);

  Stream<List<Resource>> watchChildren(PhylumAccount account);

  Stream<Iterable<ParentsResult>> watchParents(PhylumAccount account);
}

class ExplorerPageFolder extends ExplorerPage {
  final String folderId;

  ExplorerPageFolder({required this.folderId});

  @override
  Future<bool> refresh(PhylumAccount account) => account.resourceRepository.requestResource(folderId).then((result) => result.success);

  @override
  Stream<Resource?> watchResource(PhylumAccount account) => account.db.watchResource(folderId);

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) => account.db.watchChildren(folderId);

  @override
  Stream<Iterable<ParentsResult>> watchParents(PhylumAccount account) => account.db.watchParents(folderId).map((p) => p.reversed);

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
    return SynchronousFuture(true);
  }

  @override
  Stream<Resource?> watchResource(PhylumAccount account) {
    return Stream.fromIterable([null]);
  }

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) {
    return account.myListsRepository.watchRecents();
  }

  @override
  Stream<Iterable<ParentsResult>> watchParents(PhylumAccount account) {
    return Stream.fromIterable([
      [ParentsResult(id: 'recents', name: 'Recents')]
    ]);
    // return account.db.parents(folderId).watch().map((p) => p.reversed);
  }

  @override
  String toString() {
    return 'ExplorerPageRecents';
  }
}

class ExplorerPageShared extends ExplorerPage {
  const ExplorerPageShared();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.myListsRepository.refreshShared().then((result) => result.success);
  }

  @override
  Stream<Resource?> watchResource(PhylumAccount account) {
    return Stream.fromIterable([null]);
  }

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) {
    return account.myListsRepository.watchShared();
  }

  @override
  Stream<Iterable<ParentsResult>> watchParents(PhylumAccount account) {
    return Stream.fromIterable([
      [ParentsResult(id: 'shared', name: 'Shared With Me')]
    ]);
  }

  @override
  String toString() {
    return 'ExplorerPageShared';
  }
}
