import 'dart:async';

import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/search_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';

sealed class ExplorerPage {
  Uri get uri;

  String get title;

  const ExplorerPage();

  Future<bool> refresh(PhylumAccount account);

  Stream<List<Resource>> items(PhylumAccount account);
}

class ExplorerPageHome extends ExplorerPageFolder {
  @override
  Uri get uri => Uri(path: '/home');

  @override
  String get title => 'My Files';

  ExplorerPageHome(PhylumAccount account) : super(folderId: account.userHome);
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
  String get title => 'Searching for "$query"';

  final String query;
  final _streamController = StreamController<List<Resource>>.broadcast();

  ExplorerPageSearch({required this.query});

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.apiClient
        .sendRequest(
      SearchRequest(query: query),
      (request, response) => parseJsonListResponse(response, SearchResponse.fromResponse),
    )
        .then((result) {
      if (result is SearchResponse) {
        _streamController.add(result.resources.map((r) => r.resource).toList(growable: false));
      }
      return result is ApiSuccessResponse;
    });
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return _streamController.stream;
  }
}
