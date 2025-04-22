import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';

sealed class ExplorerPage {
  Uri get uri;

  String get title;

  const ExplorerPage();

  Future<bool> refresh(PhylumAccount account);

  Stream<List<Resource>> items(PhylumAccount account);
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
  Stream<List<Resource>> items(PhylumAccount account) => account.db.watchChildren(account.userHome);
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
  Stream<List<Resource>> items(PhylumAccount account) => account.db.watchChildren(folderId);
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
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectRecents().watch();
  }
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
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectTrash().watch();
  }
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
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectShared().watch();
  }
}

class ExplorerPageSearch extends ExplorerPage {
  @override
  Uri get uri => Uri(path: '/search', queryParameters: {'q': query});

  @override
  String get title => 'Search';

  final String query;

  ExplorerPageSearch({required this.query});

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.sharedResourcesRepository.refresh().then((result) => result is ApiSuccessResponse);
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectShared().watch();
  }
}
