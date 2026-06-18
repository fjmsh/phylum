import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/app/account_selector.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';

import 'routes.dart';

class PhylumRouterDelegate extends RouterDelegate<PhylumRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  PhylumRoute? get currentConfiguration => _current;

  PhylumRoute? _current;

  PhylumRouterDelegate();

  void go(PhylumRoute page) {
    if (_current != page) {
      _current = page;
      notifyListeners();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: (settings) =>
          MaterialPageRoute(builder: (context) => const AccountSelector()),
    );
  }

  @override
  Future<void> setInitialRoutePath(PhylumRoute configuration) {
    _current = configuration;
    return SynchronousFuture(null);
  }

  @override
  Future<void> setNewRoutePath(PhylumRoute configuration) {
    go(configuration);
    return SynchronousFuture(null);
  }
}

class PhylumRouteInformationParser extends RouteInformationParser<PhylumRoute> {
  const PhylumRouteInformationParser();

  @override
  Future<PhylumRoute> parseRouteInformation(RouteInformation routeInformation) {
    final uri = routeInformation.uri;
    final segments = uri.pathSegments;

    final explorerLocation = parseExplorerLocation(uri);
    if (explorerLocation != null) {
      return SynchronousFuture(ExplorerRoute(location: explorerLocation));
    }

    if (segments.length == 1) {
      if (segments[0] == 'open') {
        final resourceId = uri.queryParameters['id'];
        return SynchronousFuture(
          resourceId == null
              // TODO: Open the openresourceroute and redirect from there or show an error
              ? const ExplorerRoute(location: ExplorerLocationHome())
              : OpenResourceRoute(resourceId: resourceId),
        );
      }
    } else if (segments.length == 2) {
      if (segments[0] == 'login') {
        if (segments[1] == 'token') {
          return SynchronousFuture(
            TokenLoginRoute(
              instance: uri.queryParameters['instance'],
              token: uri.queryParameters['token'],
            ),
          );
        }
        if (segments[1] == 'reset_password') {
          return SynchronousFuture(
            ResetPasswordRoute(
              instance: uri.queryParameters['instance'],
              email: uri.queryParameters['email'],
              token: uri.queryParameters['token'],
            ),
          );
        }
      }
      if (segments[0] == 'file') {
        return SynchronousFuture(FilePreviewRoute(fileId: segments[1]));
      }
    }

    // TODO: Open a separate page for route not found;
    return SynchronousFuture(
      ExplorerRoute(location: ExplorerLocationFolder(folderId: 'unknown')),
    );
  }

  @override
  RouteInformation? restoreRouteInformation(PhylumRoute configuration) {
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
