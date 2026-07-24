import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart' show ResourceHelpers;
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/search_request.dart';
import 'package:phylum/libphylum/requests/shared_resources_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/explorer/menu/menu_option.dart';
import 'package:phylum/ui/explorer/menu/option_groups.dart';

sealed class ExplorerLocation {
  Uri get uri;

  String get title;

  const ExplorerLocation();

  String? folderId(PhylumAccount account) => null;

  Future<bool> refresh(PhylumAccount account);

  Stream<List<Resource>> items(PhylumAccount account);

  MenuOptionGroups get selectedResourceOptions => [
    [MenuOption.details, MenuOption.copyURL],
    [
      MenuOption.download,
      if (!kIsWeb && Platform.isAndroid) MenuOption.share,
      if (!kIsWeb) MenuOption.openFile,
    ],
    [MenuOption.rename, MenuOption.move, MenuOption.copy, MenuOption.delete],
    [
      MenuOption.bookmarkAdd,
      MenuOption.bookmarkRemove,
      MenuOption.permissions,
      MenuOption.publinks,
    ],
  ];

  MenuOptionGroups? get folderOptions;
}

class ExplorerLocationHome extends ExplorerLocationFolder {
  @override
  Uri get uri => Uri(path: '/');

  @override
  String get title => 'My Files';

  const ExplorerLocationHome() : super(folderId: '');

  @override
  String folderId(PhylumAccount account) => account.user.home;
}

class ExplorerLocationFolder extends ExplorerLocation {
  @override
  Uri get uri => Uri(path: '/folder/$_folderId');

  @override
  String get title => 'Folder';

  final String _folderId;

  const ExplorerLocationFolder({required this._folderId});

  @override
  String folderId(PhylumAccount account) => _folderId;

  @override
  Future<bool> refresh(PhylumAccount account) => account.resourceRepository
      .requestResource(folderId(account))
      .then((result) => result is ApiSuccessResponse);

  @override
  Stream<List<Resource>> items(PhylumAccount account) =>
      account.db.watchChildren(folderId(account));

  @override
  MenuOptionGroups get folderOptions => const [
    [MenuOption.details, MenuOption.copyURL],
    [MenuOption.newFolder, MenuOption.uploadFiles, MenuOption.uploadFolders],
    [
      MenuOption.bookmarkAdd,
      MenuOption.bookmarkRemove,
      MenuOption.permissions,
      MenuOption.publinks,
    ],
  ];
}

class ExplorerLocationRecents extends ExplorerLocation {
  @override
  Uri get uri => Uri(path: '/recents');

  @override
  String get title => 'Recents';

  const ExplorerLocationRecents();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return Future.value(true);
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectRecents().watch();
  }

  @override
  MenuOptionGroups? get folderOptions => null;
}

class ExplorerLocationTrash extends ExplorerLocation {
  @override
  Uri get uri => Uri(path: '/trash');

  @override
  String get title => 'Trash';

  const ExplorerLocationTrash();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.trashedResourcRepository.refresh().then(
      (result) => result is ApiSuccessResponse,
    );
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectTrash().watch();
  }

  @override
  MenuOptionGroups get selectedResourceOptions => const [
    [MenuOption.details],
    [MenuOption.restore, MenuOption.deleteForever],
  ];

  @override
  MenuOptionGroups? get folderOptions => [
    [MenuOption.emptyTrash],
  ];
}

class ExplorerLocationShared extends ExplorerLocation {
  @override
  Uri get uri => Uri(path: '/shared');

  @override
  String get title => 'Shared';

  const ExplorerLocationShared();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.apiClient
        .sendRequest(SharedResourcesRequest())
        .then((result) => result is ApiSuccessResponse);
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectShared().watch();
  }

  @override
  MenuOptionGroups? get folderOptions => null;
}

class ExplorerLocationSearch extends ExplorerLocation {
  @override
  Uri get uri => Uri(path: '/search', queryParameters: {'q': query});

  @override
  String get title => 'Searching for "$query"';

  final String query;
  final _streamController = StreamController<List<Resource>>.broadcast();

  ExplorerLocationSearch({required this.query});

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.apiClient.sendRequest(SearchRequest(query: query)).then((
      result,
    ) {
      if (result is SearchResponse) {
        _streamController.add(
          result.resources.map((r) => r.resource).toList(growable: false),
        );
      }
      return result is ApiSuccessResponse;
    });
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return _streamController.stream;
  }

  @override
  MenuOptionGroups? get folderOptions => null;
}
