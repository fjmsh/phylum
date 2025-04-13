import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';

import 'page.dart';

class ExplorerNavigator extends ChangeNotifier {
  final PhylumAccount? _account;
  ExplorerPage? _current;
  List<ExplorerPage> _back = const [];
  List<ExplorerPage> _forward = const [];

  ExplorerPage? get current => _current;
  bool get canGoBack => _back.isNotEmpty;
  bool get canGoForward => _forward.isNotEmpty;

  ExplorerNavigator({required PhylumAccount? account, ExplorerPage? page})
      : _account = account,
        _current = page;

  void go(ExplorerPage page) {
    if (_current != page) {
      final first = _current == null;
      _back = first ? _back : [..._back, _current!];
      _forward = const [];
      _current = page;
      if (!first) {
        notifyListeners();
      }
      print('Going to $page: ${_back.length}');
      if (page is ExplorerPageFolder && _account != null && page.folderId != _account.userHome) {
        _account.db.markResourceAccess(page.folderId);
      }
    }
  }

  void goBack() {
    print('At $_current, going back ${_back.length}');
    if (!canGoBack) return;
    int len = _back.length;
    final target = _back[len - 1];
    _current = target;
    _back = _back.sublist(0, len - 1);
    _forward = [..._forward, current!];
    print('Going back to $_current, ${_forward.length}');
    notifyListeners();
  }

  void goForward() {
    if (!canGoForward) return;
    int len = _forward.length;
    final target = _forward[len - 1];
    _current = target;
    _back = [..._back, _current!];
    _forward = _forward.sublist(0, len - 1);
    notifyListeners();
  }
}
