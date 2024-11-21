import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:state_notifier/state_notifier.dart';

sealed class NavDestination {
  const NavDestination();

  void go(BuildContext context);
}

class NavDestinationHome extends NavDestination {
  const NavDestinationHome();

  @override
  void go(BuildContext context) {
    context.goNamed('home');
  }
}

class NavDestinationFolder extends NavDestination {
  final String folderId;

  NavDestinationFolder({required this.folderId});

  @override
  void go(BuildContext context) {
    context.goNamed('folder', pathParameters: {'id': folderId});
  }
}

class NavHistoryState {
  final List<String> _back;
  final List<String> _forward;

  bool get canGoBack => _back.isNotEmpty;
  bool get canGoForward => _forward.isNotEmpty;

  const NavHistoryState({List<String> back = const [], List<String> forward = const []})
      : _back = back,
        _forward = forward;

  NavHistoryState copyWith({List<String>? back, List<String>? forward}) {
    return NavHistoryState(forward: forward ?? _forward, back: back ?? _back);
  }
}

class NavHistoryManager extends StateNotifier<NavHistoryState> {
  NavHistoryManager() : super(const NavHistoryState());

  void go(BuildContext context, NavDestination dest) {
    dest.go(context);
  }

  void goBack(BuildContext context) {
    if (!state.canGoBack) return;
    int len = state._back.length;
    final folderId = state._back[len - 1];
    state = state.copyWith(back: state._back.sublist(0, len - 1));
    context.goNamed('folder', pathParameters: {'id': folderId});
  }

  void goForward(BuildContext context) {
    if (!state.canGoForward) return;
    int len = state._forward.length;
    final folderId = state._forward[len - 1];
    state = state.copyWith(forward: state._forward.sublist(0, len - 1));
    context.goNamed('folder', pathParameters: {'id': folderId});
  }

  // void _handlePush(String folderId) {
  //   Future.microtask(() {
  //     switch (_pushState) {
  //       case _NavState.idle:
  //         state = NavHistoryState(back: [...state._back, folderId], forward: []);
  //       case _NavState.back:
  //         state = state.copyWith(forward: [...state._forward, folderId]);
  //       case _NavState.forward:
  //         state = state.copyWith(back: [...state._back, folderId]);
  //     }
  //     _pushState = _NavState.idle;
  //   });
  // }
}
