import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

sealed class NavDestination {
  const NavDestination();

  Future<bool> refresh(PhylumAccount account);

  Stream<Resource?> watchResource(PhylumAccount account);

  Stream<List<Resource>> watchChildren(PhylumAccount account);

  Stream<Iterable<ParentsResult>> watchParents(PhylumAccount account);
}

class NavDestinationFolder extends NavDestination {
  final String folderId;

  NavDestinationFolder({required this.folderId});

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.resourceRepository.requestResource(folderId).then((result) => result.success);
  }

  @override
  Stream<Resource?> watchResource(PhylumAccount account) {
    return account.resourceRepository.watchResource(folderId);
  }

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) {
    return account.resourceRepository.watchChildren(folderId);
  }

  @override
  Stream<Iterable<ParentsResult>> watchParents(PhylumAccount account) {
    return account.db.parents(folderId).watch().map((p) => p.reversed);
  }

  @override
  String toString() {
    return 'NavDestinationFolder($folderId)';
  }

  @override
  bool operator ==(Object other) {
    return other is NavDestinationFolder && other.folderId == folderId;
  }

  @override
  int get hashCode => folderId.hashCode;
}
