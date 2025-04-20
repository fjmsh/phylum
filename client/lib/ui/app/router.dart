import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:provider/provider.dart';

import '../explorer/page.dart';

class PhylumRouterDelegate extends RouterDelegate<ExplorerPage> with ChangeNotifier, PopNavigatorRouterDelegateMixin {
  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  final PhylumAccount? _account;
  ExplorerPage? _current;
  List<ExplorerPage> _back = const [];
  List<ExplorerPage> _forward = const [];

  ExplorerPage? get current => _current;

  @override
  ExplorerPage? get currentConfiguration => _current;

  PhylumRouterDelegate({required PhylumAccount? account, ExplorerPage? page})
      : _account = account,
        _current = page;

  void go(ExplorerPage page) {
    if (_current != page) {
      _back = [..._back, _current!];
      _forward = const [];
      _current = page;
      notifyListeners();
      if (page is ExplorerPageFolder && _account != null && page.folderId != _account.userHome) {
        _account.db.markResourceAccess(page.folderId);
      }
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
