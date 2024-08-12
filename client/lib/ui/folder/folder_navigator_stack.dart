import 'package:state_notifier/state_notifier.dart';

class FolderNavigatorState {
  final String root;
  final List<String> _stack;

  bool get isRoot => _stack.isEmpty;

  String get folderId => isRoot ? root : _stack.last;

  const FolderNavigatorState({required this.root, required List<String> stack}) : _stack = stack;
}

class FolderNavigatorStack extends StateNotifier<FolderNavigatorState> {
  final String root;

  FolderNavigatorStack(this.root) : super(FolderNavigatorState(root: root, stack: const []));

  bool pop() {
    if (state.isRoot) return false;
    state = FolderNavigatorState(root: state.root, stack: state._stack.sublist(0, state._stack.length - 1).toList(growable: false));
    return true;
  }

  void push(String id) {
    state = FolderNavigatorState(root: state.root, stack: [...state._stack, id]);
  }
}
