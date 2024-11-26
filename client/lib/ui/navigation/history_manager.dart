import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/navigation/destination.dart';
import 'package:state_notifier/state_notifier.dart';

class NavHistoryState {
  final NavDestination current;
  final List<NavDestination> _back;
  final List<NavDestination> _forward;

  bool get canGoBack => _back.isNotEmpty;
  bool get canGoForward => _forward.isNotEmpty;

  const NavHistoryState({
    required this.current,
    List<NavDestination> back = const [],
    List<NavDestination> forward = const [],
  })  : _back = back,
        _forward = forward;

  NavHistoryState copyWith({NavDestination? current, List<NavDestination>? back, List<NavDestination>? forward}) {
    return NavHistoryState(
      current: current ?? this.current,
      back: back ?? _back,
      forward: forward ?? _forward,
    );
  }
}

class NavHistoryManager extends StateNotifier<NavHistoryState> {
  NavHistoryManager() : super(const NavHistoryState(current: NavDestinationHome()));

  void go(BuildContext context, NavDestination destination) {
    if (kIsWeb) {
      destination.go(context);
    } else {
      state = NavHistoryState(
        current: destination,
        back: [...state._back, state.current],
        forward: const [],
      );
    }
  }

  void handleDestinationChange(NavDestination destination) {
    if (kIsWeb) {
      state = NavHistoryState(
        current: destination,
      );
    } else if (destination != state.current) {
      // For handling deep links
      state = NavHistoryState(
        current: destination,
        back: [...state._back, state.current],
        forward: const [],
      );
    }
  }

  void goBack(BuildContext context) {
    if (!state.canGoBack) return;
    int len = state._back.length;
    final target = state._back[len - 1];
    state = NavHistoryState(
      current: target,
      back: state._back.sublist(0, len - 1),
      forward: [...state._forward, state.current],
    );
  }

  void goForward(BuildContext context) {
    if (!state.canGoForward) return;
    int len = state._forward.length;
    final target = state._forward[len - 1];
    state = NavHistoryState(
      current: target,
      back: [...state._back, state.current],
      forward: state._forward.sublist(0, len - 1),
    );
  }
}
