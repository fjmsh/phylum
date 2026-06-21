import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/account_selector.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/common/dialog_scaffold.dart';
import 'package:phylum/ui/explorer/scaffold/explorer_page.dart';
import 'package:phylum/ui/login/login_controller.dart';
import 'package:phylum/ui/login/login_page.dart';
import 'package:phylum/ui/setup/setup_page.dart';

part 'routes.dart';

class PhylumRouterDelegate extends RouterDelegate<PhylumRouteConfig>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  PhylumRouteConfig get currentConfiguration => _current;

  late AccountManagerState<PhylumAccount> _accountManagerState;
  PhylumRouteConfig _current = HomeRouteConfig();
  PhylumRouteConfig? next;

  final AccountManager<PhylumAccount> accountManager;

  PhylumRouterDelegate({required this.accountManager}) {
    accountManager.addListener(onAccountManagerUpdated);
  }

  void onAccountManagerUpdated(AccountManagerState<PhylumAccount> state) {
    _accountManagerState = state;
    notifyListeners();
  }

  void go(PhylumRouteConfig configuration) {
    if (_current != configuration) {
      next = _current is LoggedOutRouteConfig
          ? (_current as LoggedOutRouteConfig).next
          : null;
      _current = configuration;
      notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = resolveTarget(_current);
    final pages = switch (target) {
      LoggedOutRouteConfig() => target.buildPages(),
      LoggedInRouteConfig() => target.buildPages(
        _accountManagerState.selectedAccount!,
      ),
      HomeRouteConfig() => throw 'Not possible',
      UnknownRouteConfig() => throw 'Not possible',
    };
    return Navigator(
      key: navigatorKey,
      pages: pages,
      onDidRemovePage: (page) {},
      // onGenerateRoute: (settings) =>
      //     MaterialPageRoute(builder: (context) => const AccountSelector()),
    );
  }

  PhylumRouteConfig resolveTarget(PhylumRouteConfig target) {
    if (_accountManagerState.status != AccountManagerStatus.ready ||
        _accountManagerState.invalidAccounts.isNotEmpty) {
      return AccountManagerRouteConfig()..next = target;
    }
    final account = _accountManagerState.selectedAccount;
    if (account == null) {
      return switch (target) {
        // TODO: Unknkown page or error message?
        HomeRouteConfig() || UnknownRouteConfig() => LoginRouteConfig(),
        LoggedOutRouteConfig() =>
          target..next = next ?? const HomeRouteConfig(),
        LoggedInRouteConfig() => LoginRouteConfig()..next = target,
      };
    }

    return switch (target) {
      HomeRouteConfig() =>
        next ?? const ExplorerRoute(location: ExplorerLocationHome()),
      // TODO: Unknown error page
      UnknownRouteConfig() =>
        next ?? const ExplorerRoute(location: ExplorerLocationHome()),
      // TODO: #multi-account: Allow LoggedOutRouteConfig when account selected
      LoggedOutRouteConfig() => target.next,
      LoggedInRouteConfig() => target,
    };
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

    final explorerLocation = parseExplorerLocation(uri);

    if (explorerLocation != null) {
      return SynchronousFuture(ExplorerRoute(location: explorerLocation));
    }

    final config = switch (uri.path) {
      '/login/token' => LoginRouteConfig(
        instanceUrl: uri.queryParameters['instance'],
        loginMethod: TokenLoginMethod(uri.queryParameters['token']),
      ),
      '/login/reset_password' => LoginRouteConfig(
        instanceUrl: uri.queryParameters['instance'],
        loginMethod: ResetPasswordMethod(
          email: uri.queryParameters['email'],
          token: uri.queryParameters['token'],
        ),
      ),
      _ => UnknownRouteConfig(uri: uri),
    };

    return SynchronousFuture(config);

    //   // if (segments[0] == 'file') {
    //   //   return SynchronousFuture(FilePreviewRoute(fileId: segments[1]));
    //   // }
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
