import 'dart:async';

import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/search_request.dart';
import 'package:phylum/libphylum/requests/shared_resources_request.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/layout/app_layout.dart';
import 'package:phylum/ui/login/login_page.dart';
import 'package:phylum/ui/login/oauth_login_page.dart';
import 'package:phylum/ui/login/reset_password_page.dart';
import 'package:provider/provider.dart';

sealed class PhylumRoute {
  Uri get uri;

  const PhylumRoute();

  Widget buildPage(BuildContext context);
}

class OAuthLoginRoute extends PhylumRoute {
  final String code;
  final String state;

  OAuthLoginRoute({required this.code, required this.state});

  @override
  Uri get uri => Uri(path: '/login/oauth');

  @override
  Widget buildPage(BuildContext context) {
    return OAuthLoginPage(
      code: code,
      state: state,
    );
  }
}

class ResetPasswordRoute extends PhylumRoute {
  final Uri instanceUri;
  final String email;
  final String token;

  ResetPasswordRoute({required this.instanceUri, required this.email, required this.token});

  @override
  Uri get uri => Uri(path: '/reset_password');

  @override
  Widget buildPage(BuildContext context) => ResetPasswordPage(
        instanceUrl: instanceUri,
        email: email,
        token: token,
      );
}

sealed class ExplorerRoute extends PhylumRoute {
  String get title;

  const ExplorerRoute();

  String? folderId(PhylumAccount account) => null;

  Future<bool> refresh(PhylumAccount account);

  Stream<List<Resource>> items(PhylumAccount account);

  @override
  Widget buildPage(BuildContext context) {
    final account =
        context.select<AccountManagerState<PhylumAccount>, PhylumAccount?>((state) => state.selectedAccount);

    if (account == null) {
      return const LoginPage();
    }
    return AppLayout.create(account);
  }
}

class ExplorerRouteHome extends ExplorerRouteFolder {
  @override
  Uri get uri => Uri(path: '/');

  @override
  String get title => 'My Files';

  ExplorerRouteHome() : super(folderId: '');

  @override
  String folderId(PhylumAccount account) => account.user.home;
}

class ExplorerRouteFolder extends ExplorerRoute {
  @override
  Uri get uri => Uri(path: '/folder/$_folderId');

  @override
  String get title => 'Folder';

  final String _folderId;

  ExplorerRouteFolder({required String folderId}) : _folderId = folderId;

  @override
  String folderId(PhylumAccount account) => _folderId;

  @override
  Future<bool> refresh(PhylumAccount account) =>
      account.resourceRepository.requestResource(folderId(account)).then((result) => result is ApiSuccessResponse);

  @override
  Stream<List<Resource>> items(PhylumAccount account) => account.db.watchChildren(folderId(account));
}

class ExplorerRouteRecents extends ExplorerRoute {
  @override
  Uri get uri => Uri(path: '/recents');

  @override
  String get title => 'Recents';

  const ExplorerRouteRecents();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return Future.value(true);
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectRecents().watch();
  }
}

class ExplorerRouteTrash extends ExplorerRoute {
  @override
  Uri get uri => Uri(path: '/trash');

  @override
  String get title => 'Trash';

  const ExplorerRouteTrash();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.trashedResourcRepository.refresh().then((result) => result is ApiSuccessResponse);
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectTrash().watch();
  }
}

class ExplorerRouteShared extends ExplorerRoute {
  @override
  Uri get uri => Uri(path: '/shared');

  @override
  String get title => 'Shared';

  const ExplorerRouteShared();

  @override
  Future<bool> refresh(PhylumAccount account) {
    return account.apiClient
        .sendRequest(
          SharedResourcesRequest(),
          (request, response) => parseJsonMapResponse(response, SharedResourcesResponse.fromResponse),
        )
        .then((result) => result is ApiSuccessResponse);
  }

  @override
  Stream<List<Resource>> items(PhylumAccount account) {
    return account.db.selectShared().watch();
  }
}

class ExplorerRouteSearch extends ExplorerRoute {
  @override
  Uri get uri => Uri(path: '/search', queryParameters: {'q': query});

  @override
  String get title => 'Searching for "$query"';

  final String query;
  final _streamController = StreamController<List<Resource>>.broadcast();

  ExplorerRouteSearch({required this.query});

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
