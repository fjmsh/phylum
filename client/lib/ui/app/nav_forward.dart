import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:state_notifier/state_notifier.dart';

class NavForwardState {
  final List<String> _popped;

  bool get canGoForward => _popped.isNotEmpty;

  const NavForwardState({List<String> popped = const []}) : _popped = popped;
}

class NavForwardManager extends StateNotifier<NavForwardState> {
  bool _ignoreClear = false;
  late final NavigatorObserver navObserver = _Observer._(historyManager: this);

  NavForwardManager() : super(const NavForwardState());

  void goForward(BuildContext context) {
    if (!state.canGoForward) return;
    int len = state._popped.length;
    final folderId = state._popped[len - 1];
    state = NavForwardState(popped: state._popped.sublist(0, len - 1));
    _ignoreClear = true;
    context.pushNamed('folder', pathParameters: {'id': folderId});
  }

  void _add(String id) {
    Future.microtask(() => state = NavForwardState(popped: [...state._popped, id]));
  }

  void _maybeClear() {
    if (!_ignoreClear) {
      Future.microtask(() => state = const NavForwardState(popped: []));
    }
    _ignoreClear = false;
  }
}

class _Observer extends NavigatorObserver {
  final NavForwardManager historyManager;

  _Observer._({required this.historyManager});

  @override
  void didPush(Route route, Route? previousRoute) {
    if (route.settings.name == 'folder') {
      historyManager._maybeClear();
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (route.settings.name == 'folder') {
      historyManager._add(route.settings.arguments as String);
    }
  }
}
