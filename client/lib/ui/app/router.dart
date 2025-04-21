import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:provider/provider.dart';

import '../explorer/page.dart';

class PhylumRouterDelegate extends RouterDelegate<ExplorerPage> with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();
  ExplorerPage? _current;
  List<ExplorerPage> _back = const [];
  List<ExplorerPage> _forward = const [];

  ExplorerPage? get current => _current;

  @override
  ExplorerPage? get currentConfiguration => _current;

  PhylumRouterDelegate({ExplorerPage? page}) : _current = page;

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
    _forward = [..._forward, current!];
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
    return ChangeNotifierProvider.value(
      value: this,
      child: Navigator(
        key: navigatorKey,
        onGenerateRoute: (settings) => MaterialPageRoute(builder: (context) => AppLayout.create()),
      ),
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
      return SynchronousFuture(const ExplorerPageHome());
    }
    if (segments.length == 1) {
      if (segments[0] == 'home') {
        return SynchronousFuture(const ExplorerPageHome());
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
