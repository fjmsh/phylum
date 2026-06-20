import 'package:state_notifier/state_notifier.dart';

import 'explorer_location.dart';

class ExplorerHistory {
  final ExplorerLocation location;
  final List<ExplorerLocation> back;
  final List<ExplorerLocation> forward;

  ExplorerHistory({
    required this.location,
    required this.back,
    required this.forward,
  });
}

class ExplorerHistoryController extends StateNotifier<ExplorerHistory> {
  bool get canGoBack => state.back.isNotEmpty;
  ExplorerLocation get currentLocation => state.location;

  ExplorerHistoryController({required ExplorerLocation initialLocation})
    : super(
        ExplorerHistory(
          location: initialLocation,
          back: const [],
          forward: const [],
        ),
      );

  void go(ExplorerLocation location) {
    if (state.location != location) {
      state = ExplorerHistory(
        location: location,
        back: [...state.back, state.location],
        forward: const [],
      );
    }
  }

  bool goBack() {
    if (state.back.isEmpty) return false;
    state = ExplorerHistory(
      location: state.back.last,
      back: List.of(state.back)..removeLast(),
      forward: [...state.forward, state.location],
    );

    return true;
  }

  bool goForward() {
    if (state.forward.isEmpty) return false;
    state = ExplorerHistory(
      location: state.forward.first,
      back: [...state.back, state.location],
      forward: List.of(state.forward)..removeAt(0),
    );
    return true;
  }
}
