import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'page.dart';

class PhylumRouterDelegate extends RouterDelegate<ExplorerPage> with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  @override
  ExplorerPage? get currentConfiguration => _current;

  final Widget Function(BuildContext)? builder;
  ExplorerPage? _current;
  List<ExplorerPage> _back = const [];
  List<ExplorerPage> _forward = const [];

  PhylumRouterDelegate({this.builder, ExplorerPage? page}) : _current = page;

  bool get canGoBack => _back.isNotEmpty;

  void go(ExplorerPage page) {
    if (_current != page) {
      _back = [..._back, _current!];
      _forward = const [];
      _current = page;
      notifyListeners();
    }
  }

  void goBack() {
    if (_back.isEmpty) return;
    int len = _back.length;
    final target = _back[len - 1];
    _back = _back.sublist(0, len - 1);
    _forward = [..._forward, _current!];
    _current = target;
    notifyListeners();
  }

  void goForward() {
    if (_forward.isEmpty) return;
    int len = _forward.length;
    final target = _forward[len - 1];
    _back = [..._back, _current!];
    _forward = _forward.sublist(0, len - 1);
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
  Future<void> setInitialRoutePath(ExplorerPage configuration) {
    _current = configuration;
    return SynchronousFuture(null);
  }

  @override
  Future<void> setNewRoutePath(ExplorerPage configuration) {
    go(configuration);
    return SynchronousFuture(null);
  }
}

class PhylumRouteInformationParser extends RouteInformationParser<ExplorerPage> {
  const PhylumRouteInformationParser();

  @override
  Future<ExplorerPage> parseRouteInformation(RouteInformation routeInformation) {
    final uri = routeInformation.uri;
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return SynchronousFuture(ExplorerPageHome());
    }
    if (segments.length == 1) {
      if (segments[0] == 'home') {
        return SynchronousFuture(ExplorerPageHome());
      }
      if (segments[0] == 'recents') {
        return SynchronousFuture(const ExplorerPageRecents());
      }
      if (segments[0] == 'shared') {
        return SynchronousFuture(const ExplorerPageShared());
      }
      if (segments[0] == 'trash') {
        return SynchronousFuture(const ExplorerPageTrash());
      }
      if (segments[0] == 'search') {
        final query = uri.queryParameters['q'];
        if (query == null || query.trim().isEmpty) {
          return SynchronousFuture(ExplorerPageHome());
        }
        return SynchronousFuture(ExplorerPageSearch(query: query));
      }
    } else if (segments.length == 2 && segments[0] == 'folder') {
      return SynchronousFuture(ExplorerPageFolder(folderId: segments[1]));
    }
    return SynchronousFuture(ExplorerPageFolder(folderId: 'unknown'));
  }

  @override
  RouteInformation? restoreRouteInformation(ExplorerPage configuration) {
    return RouteInformation(uri: configuration.uri);
  }
}
