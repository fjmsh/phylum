import 'package:state_notifier/state_notifier.dart';

import 'destination.dart';

class ExplorerNavigatorState {
  final NavDestination current;
  final List<NavDestination> _back;
  final List<NavDestination> _forward;

  bool get canGoBack => _back.isNotEmpty;
  bool get canGoForward => _forward.isNotEmpty;

  const ExplorerNavigatorState({
    required this.current,
    List<NavDestination> back = const [],
    List<NavDestination> forward = const [],
  })  : _back = back,
        _forward = forward;

  ExplorerNavigatorState copyWith({NavDestination? current, List<NavDestination>? back, List<NavDestination>? forward}) {
    return ExplorerNavigatorState(
      current: current ?? this.current,
      back: back ?? _back,
      forward: forward ?? _forward,
    );
  }
}

class ExplorerNavigator extends StateNotifier<ExplorerNavigatorState> {
  NavDestination get current => state.current;

  ExplorerNavigator(NavDestination destination) : super(ExplorerNavigatorState(current: destination));

  void go(NavDestination destination) {
    if (state.current != destination) {
      state = ExplorerNavigatorState(
        current: destination,
        back: [...state._back, state.current],
        forward: const [],
      );
    }
  }

  void goBack() {
    if (!state.canGoBack) return;
    int len = state._back.length;
    final target = state._back[len - 1];
    state = ExplorerNavigatorState(
      current: target,
      back: state._back.sublist(0, len - 1),
      forward: [...state._forward, state.current],
    );
  }

  void goForward() {
    if (!state.canGoForward) return;
    int len = state._forward.length;
    final target = state._forward[len - 1];
    state = ExplorerNavigatorState(
      current: target,
      back: [...state._back, state.current],
      forward: state._forward.sublist(0, len - 1),
    );
  }
}
