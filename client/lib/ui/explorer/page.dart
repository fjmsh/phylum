import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';

sealed class ExplorerPage {
  Uri get uri;

  const ExplorerPage();

  Future<bool> refresh(PhylumAccount account);

  Stream<Resource?> watchResource(PhylumAccount account);

  Stream<List<Resource>> watchChildren(PhylumAccount account);

  String get title;
}

class ExplorerPageHome extends ExplorerPage {
  @override
  Uri get uri => Uri(path: '/home');

  @override
  String get title => 'My Files';

  const ExplorerPageHome();

  @override
  Future<bool> refresh(PhylumAccount account) =>
      account.resourceRepository.requestResource(account.userHome).then((result) => result is ApiSuccessResponse);

  @override
  Stream<Resource?> watchResource(PhylumAccount account) => account.db.watchResource(account.userHome);

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) => account.db.watchChildren(account.userHome);

  @override
  String toString() => 'ExplorerPageHome';

  @override
  bool operator ==(Object other) {
    return other is ExplorerPageHome;
  }

  @override
  int get hashCode => 'home'.hashCode;
}

class ExplorerPageFolder extends ExplorerPage {
  @override
  Uri get uri => Uri(path: '/folder/$folderId');

  @override
  String get title => 'Folder';

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
  String toString() => 'ExplorerPageFolder($folderId)';

  @override
  bool operator ==(Object other) {
    return other is ExplorerPageFolder && other.folderId == folderId;
  }

  @override
  int get hashCode => folderId.hashCode;
}

class ExplorerPageRecents extends ExplorerPage {
  @override
  Uri get uri => Uri(path: '/recents');

  @override
  String get title => 'Recents';

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
  String toString() {
    return 'ExplorerPageRecents';
  }

  @override
  bool operator ==(Object other) {
    return other is ExplorerPageRecents;
  }

  @override
  int get hashCode => 'recents'.hashCode;
}

class ExplorerPageTrash extends ExplorerPage {
  @override
  Uri get uri => Uri(path: '/trash');

  @override
  String get title => 'Trash';

  const ExplorerPageTrash();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.trashedResourcRepository.refresh().then((result) => result is ApiSuccessResponse);
  }

  @override
  Stream<Resource?> watchResource(PhylumAccount account) {
    return Stream.fromIterable([null]);
  }

  @override
  Stream<List<Resource>> watchChildren(PhylumAccount account) {
    return account.db.selectTrash().watch();
  }

  @override
  String toString() {
    return 'ExplorerPageTrash';
  }

  @override
  bool operator ==(Object other) {
    return other is ExplorerPageTrash;
  }

  @override
  int get hashCode => 'trash'.hashCode;
}

class ExplorerPageShared extends ExplorerPage {
  @override
  Uri get uri => Uri(path: '/shared');

  @override
  String get title => 'Shared';

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
  String toString() {
    return 'ExplorerPageShared';
  }

  @override
  bool operator ==(Object other) {
    return other is ExplorerPageShared;
  }

  @override
  int get hashCode => 'shared'.hashCode;
}
