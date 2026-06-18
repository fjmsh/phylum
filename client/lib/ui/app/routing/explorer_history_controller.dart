import 'package:state_notifier/state_notifier.dart';

import 'explorer_location.dart';

class ExplorerHistory {
  final ExplorerLocation current;
  final List<ExplorerLocation> back;
  final List<ExplorerLocation> forward;

  ExplorerHistory({
    required this.current,
    required this.back,
    required this.forward,
  });
}

class ExplorerHistoryController extends StateNotifier<ExplorerHistory> {
  ExplorerHistoryController({required ExplorerLocation initialLocation})
    : super(
        ExplorerHistory(
          current: initialLocation,
          back: const [],
          forward: const [],
        ),
      );

  bool get canGoBack => state.back.isNotEmpty;

  void go(ExplorerLocation location) {
    if (state.current != location) {
      state = ExplorerHistory(
        current: location,
        back: [...state.back, state.current],
        forward: const [],
      );
    }
  }

  bool goBack() {
    if (state.back.isEmpty) return false;
    state = ExplorerHistory(
      current: state.back.last,
      back: List.of(state.back)..removeLast(),
      forward: [...state.forward, state.current],
    );

    return true;
  }

  bool goForward() {
    if (state.forward.isEmpty) return false;
    state = ExplorerHistory(
      current: state.forward.first,
      back: [...state.back, state.current],
      forward: List.of(state.forward)..removeAt(0),
    );
    return true;
  }
}

abstract class ExplorerLocationParser {
  static ExplorerLocation parseLocation(Uri uri) {
    final segments = uri.pathSegments;

    if (segments.isEmpty) {
      return ExplorerLocationHome();
    }
    if (segments.length == 1) {
      if (segments[0] == 'home') {
        return ExplorerLocationHome();
      }
      if (segments[0] == 'recents') {
        return const ExplorerLocationRecents();
      }
      if (segments[0] == 'shared') {
        return const ExplorerLocationShared();
      }
      if (segments[0] == 'trash') {
        return const ExplorerLocationTrash();
      }
      if (segments[0] == 'search') {
        final query = uri.queryParameters['q'];
        if (query == null || query.trim().isEmpty) {
          return ExplorerLocationHome();
        }
        return ExplorerLocationSearch(query: query);
      }
    } else if (segments.length == 2) {
      if (segments[0] == 'folder') {
        return ExplorerLocationFolder(folderId: segments[1]);
      }
    }
    return ExplorerLocationFolder(folderId: 'unknown');
  }
}
