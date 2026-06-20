import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:path/path.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';

import 'routes.dart';

class PhylumRouterDelegate extends RouterDelegate<PhylumRouteConfig>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  PhylumRouteConfig get currentConfiguration => _current;

  late AccountManagerState<PhylumAccount> _accountManagerState;
  PhylumRouteConfig _current = HomeRouteConfig();

  final AccountManager<PhylumAccount> accountManager;

  PhylumRouterDelegate({required this.accountManager}) {
    accountManager.addListener(onAccountManagerUpdated);
  }

  void onAccountManagerUpdated(AccountManagerState<PhylumAccount> state) {
    _accountManagerState = state;
    notifyListeners();
  }

  void go(PhylumRouteConfig page) {
    if (_current != page) {
      _current = page;
      notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = getTarget(_current);
    final pages = switch (target) {
      LoggedOutRouteConfig() => target.buildPages(),
      LoggedInRouteConfig() => target.buildPages(
        _accountManagerState.selectedAccount!,
      ),
      HomeRouteConfig() => throw 'Not possible',
    };
    return Navigator(
      key: navigatorKey,
      pages: pages,
      onDidRemovePage: (page) {},
      // onGenerateRoute: (settings) =>
      //     MaterialPageRoute(builder: (context) => const AccountSelector()),
    );
  }

  PhylumRouteConfig getTarget(PhylumRouteConfig current) {
    PhylumRouteConfig target = current;
    if (_accountManagerState.status != AccountManagerStatus.ready ||
        _accountManagerState.invalidAccounts.isNotEmpty) {
      return AccountManagerRouteConfig(next: target);
    }
    final account = _accountManagerState.selectedAccount;
    if (account == null) {
      if (target is LoggedInRouteConfig) {
        return LoginRouteConfig(next: target);
      }
      return target;
    }

    // TODO: #multi-account
    if (target is LoggedOutRouteConfig || target is HomeRouteConfig) {
      target = ExplorerRoute(location: ExplorerLocationHome());
    }

    return target;
  }

  @override
  Future<void> setInitialRoutePath(PhylumRouteConfig configuration) {
    _current = configuration;
    return SynchronousFuture(null);
  }

  @override
  Future<void> setNewRoutePath(PhylumRouteConfig configuration) {
    go(configuration);
    return SynchronousFuture(null);
  }
}

class PhylumRouteInformationParser
    extends RouteInformationParser<PhylumRouteConfig> {
  const PhylumRouteInformationParser();

  @override
  Future<PhylumRouteConfig> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final uri = routeInformation.uri;
    final segments = uri.pathSegments;

    final explorerLocation = parseExplorerLocation(uri);

    if (explorerLocation != null) {
      return SynchronousFuture(ExplorerRoute(location: explorerLocation));
    }

    if (segments.length == 1) {
      // if (segments[0] == 'open') {
      //   final resourceId = uri.queryParameters['id'];
      //   return SynchronousFuture(
      //     resourceId == null
      //         // TODO: Open the openresourceroute and redirect from there or show an error
      //         ? const ExplorerRoute(location: ExplorerLocationHome())
      //         : OpenResourceRoute(resourceId: resourceId),
      //   );
      // }
    } else if (segments.length == 2) {
      // if (segments[0] == 'login') {
      //   if (segments[1] == 'token') {
      //     return SynchronousFuture(
      //       TokenLoginRoute(
      //         instance: uri.queryParameters['instance'],
      //         token: uri.queryParameters['token'],
      //       ),
      //     );
      //   }
      //   if (segments[1] == 'reset_password') {
      //     return SynchronousFuture(
      //       ResetPasswordRoute(
      //         instance: uri.queryParameters['instance'],
      //         email: uri.queryParameters['email'],
      //         token: uri.queryParameters['token'],
      //       ),
      //     );
      //   }
      // }
      // if (segments[0] == 'file') {
      //   return SynchronousFuture(FilePreviewRoute(fileId: segments[1]));
      // }
    }

    // TODO: Open a separate page for route not found;
    return SynchronousFuture(
      ExplorerRoute(location: ExplorerLocationFolder(folderId: 'unknown')),
    );
  }

  @override
  RouteInformation? restoreRouteInformation(PhylumRouteConfig configuration) {
    return RouteInformation(uri: configuration.uri);
  }

  ExplorerLocation? parseExplorerLocation(Uri uri) {
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return ExplorerLocationHome();
    }
    if (segments.length == 1) {
      if (segments[0] == 'home') {
        return ExplorerLocationHome();
      }
      if (segments[0] == 'recents') {
        return const ExplorerLocationRecents();
      }
      if (segments[0] == 'shared') {
        return const ExplorerLocationShared();
      }
      if (segments[0] == 'trash') {
        return const ExplorerLocationTrash();
      }
      if (segments[0] == 'search') {
        final query = uri.queryParameters['q'];
        if (query == null || query.trim().isEmpty) {
          return ExplorerLocationHome();
        }
        return ExplorerLocationSearch(query: query);
      }
    } else if (segments.length == 2) {
      if (segments[0] == 'folder') {
        return ExplorerLocationFolder(folderId: segments[1]);
      }
    }
    return null;
  }
}
