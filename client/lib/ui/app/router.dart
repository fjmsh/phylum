import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/util/base_uri.dart';
import 'package:phylum/util/logging.dart';

import 'routes.dart';

class PhylumRouterDelegate extends RouterDelegate<PhylumRoute> with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  PhylumRoute? get currentConfiguration => _current;

  final Widget Function(BuildContext)? builder;
  PhylumRoute? _current;
  List<ExplorerRoute> _back = const [];
  List<ExplorerRoute> _forward = const [];

  PhylumRouterDelegate({this.builder, ExplorerRoute? page}) : _current = page;

  bool get canGoBack => _back.isNotEmpty;

  void go(PhylumRoute page) {
    if (_current != page) {
      if (_current is ExplorerRoute) {
        _back = [..._back, _current as ExplorerRoute];
        _forward = const [];
      }
      _current = page;
      notifyListeners();
    }
  }

  void goBack() {
    if (_back.isEmpty) return;
    int len = _back.length;
    final target = _back[len - 1];
    if (_current is ExplorerRoute) {
      _back = _back.sublist(0, len - 1);
      _forward = [..._forward, _current as ExplorerRoute];
    }
    _current = target;
    notifyListeners();
  }

  void goForward() {
    if (_forward.isEmpty) return;
    int len = _forward.length;
    final target = _forward[len - 1];
    if (_current is ExplorerRoute) {
      _back = [..._back, _current as ExplorerRoute];
      _forward = _forward.sublist(0, len - 1);
    }
    _current = target;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      onGenerateRoute: builder == null ? null : (settings) => MaterialPageRoute(builder: builder!),
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

    if (segments.isEmpty) {
      return SynchronousFuture(ExplorerRouteHome());
    }
    if (segments.length == 1) {
      if (segments[0] == 'home') {
        return SynchronousFuture(ExplorerRouteHome());
      }
      if (segments[0] == 'recents') {
        return SynchronousFuture(const ExplorerRouteRecents());
      }
      if (segments[0] == 'shared') {
        return SynchronousFuture(const ExplorerRouteShared());
      }
      if (segments[0] == 'trash') {
        return SynchronousFuture(const ExplorerRouteTrash());
      }
      if (segments[0] == 'reset_password') {
        Uri? instanceUrl = Uri.tryParse(uri.queryParameters['instance'] ?? '');

        if (instanceUrl == null) {
          logger.w('Unable to parse instance URL "${uri.queryParameters['instance']}"');
        } else if (kIsWeb) {
          if (kDebugMode && instanceUrl != webAppBaseUri) {
            logger.w('Instance URL "${uri.queryParameters['instance']}" does not match Uri.base $webAppBaseUri');
          }
          instanceUrl = Uri();
        }

        return SynchronousFuture(ResetPasswordRoute(
          instanceUri: instanceUrl ?? Uri(),
          email: uri.queryParameters['email'] ?? '',
          token: uri.queryParameters['token'] ?? '',
        ));
      }
      if (segments[0] == 'search') {
        final query = uri.queryParameters['q'];
        if (query == null || query.trim().isEmpty) {
          return SynchronousFuture(ExplorerRouteHome());
        }
        return SynchronousFuture(ExplorerRouteSearch(query: query));
      }
    } else if (segments.length == 2 && segments[0] == 'folder') {
      return SynchronousFuture(ExplorerRouteFolder(folderId: segments[1]));
    }
    return SynchronousFuture(ExplorerRouteFolder(folderId: 'unknown'));
  }

  @override
  RouteInformation? restoreRouteInformation(PhylumRoute configuration) {
    return RouteInformation(uri: configuration.uri);
  }
}
