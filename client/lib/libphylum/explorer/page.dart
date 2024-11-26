import 'package:phylum/libphylum/db/db.dart';
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
    return 'ExplorerPageFolder($folderId)';
  }

  @override
  bool operator ==(Object other) {
    return other is ExplorerPageFolder && other.folderId == folderId;
  }

  @override
  int get hashCode => folderId.hashCode;
}
