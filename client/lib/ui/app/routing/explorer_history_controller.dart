import 'package:phylum/ui/app/routing/router.dart';
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
  final PhylumRouterDelegate? _routerDelegate;
  ExplorerLocation get currentLocation => state.location;
  bool get canGoBack => state.back.isNotEmpty;

  ExplorerHistoryController({
    this._routerDelegate,
    required ExplorerLocation initialLocation,
  }) : super(
         ExplorerHistory(
           location: initialLocation,
           back: const [],
           forward: const [],
         ),
       );

  void go(ExplorerLocation location) {
    if (_routerDelegate == null) {
      update(location);
    } else {
      _routerDelegate.go(ExplorerRoute(location: location));
    }
  }

  void update(ExplorerLocation location) {
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
      location: state.forward.last,
      back: [...state.back, state.location],
      forward: List.of(state.forward)..removeLast(),
    );
    return true;
  }
}
