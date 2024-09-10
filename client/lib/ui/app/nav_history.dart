import 'package:state_notifier/state_notifier.dart';

class NavHistoryState {
  final List<String> _stack;
  final int _offset;

  bool get canGoBack => _stack.length > (_offset + 1);

  bool get canGoForward => _offset > 0;

  String get folderId => _stack[_stack.length - _offset - 1];

  const NavHistoryState({required List<String> stack, int offset = 0})
      : _offset = offset,
        _stack = stack;
}

class NavHistoryManager extends StateNotifier<NavHistoryState> {
  NavHistoryManager(String id) : super(NavHistoryState(stack: [id]));

  bool goBack() {
    if (!state.canGoBack) return false;
    state = NavHistoryState(stack: state._stack, offset: state._offset + 1);
    return true;
  }

  bool goForward() {
    if (!state.canGoForward) return false;
    state = NavHistoryState(stack: state._stack, offset: state._offset - 1);
    return true;
  }

  void go(String id) {
    state = NavHistoryState(stack: [...state._stack.sublist(0, state._stack.length - state._offset), id]);
  }
}
