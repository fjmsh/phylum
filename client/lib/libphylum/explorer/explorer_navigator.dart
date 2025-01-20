import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:state_notifier/state_notifier.dart';

import 'page.dart';

class ExplorerNavigatorState {
  final ExplorerPage current;
  final List<ExplorerPage> _back;
  final List<ExplorerPage> _forward;

  bool get canGoBack => _back.isNotEmpty;
  bool get canGoForward => _forward.isNotEmpty;

  const ExplorerNavigatorState({
    required this.current,
    List<ExplorerPage> back = const [],
    List<ExplorerPage> forward = const [],
  })  : _back = back,
        _forward = forward;

  ExplorerNavigatorState copyWith({ExplorerPage? current, List<ExplorerPage>? back, List<ExplorerPage>? forward}) {
    return ExplorerNavigatorState(
      current: current ?? this.current,
      back: back ?? _back,
      forward: forward ?? _forward,
    );
  }
}

class ExplorerNavigator extends StateNotifier<ExplorerNavigatorState> {
  final PhylumAccount? _account;
  ExplorerPage get current => state.current;

  ExplorerNavigator({required PhylumAccount? account, required ExplorerPage page})
      : _account = account,
        super(ExplorerNavigatorState(current: page));

  void go(ExplorerPage page) {
    if (state.current != page) {
      state = ExplorerNavigatorState(
        current: page,
        back: [...state._back, state.current],
        forward: const [],
      );
      if (page is ExplorerPageFolder && _account != null && page.folderId != _account.userHome) {
        _account.db.markResourceAccess(page.folderId);
      }
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
