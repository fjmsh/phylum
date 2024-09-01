import 'package:state_notifier/state_notifier.dart';

class FolderNavigatorState {
  final String root;
  final String name;
  final List<(String, String)> _stack;
  List<(String, String)> get stack => _stack;

  bool get isRoot => _stack.isEmpty;

  String get folderId => isRoot ? root : _stack.last.$1;

  const FolderNavigatorState({required this.root, required this.name, required List<(String, String)> stack}) : _stack = stack;
}

class FolderNavigatorStack extends StateNotifier<FolderNavigatorState> {
  FolderNavigatorStack(String root, String name) : super(FolderNavigatorState(root: root, name: name, stack: const []));

  bool pop() {
    return popTo(state._stack.length - 1);
  }

  bool popTo(int index) {
    if (state._stack.length <= index) return false;
    state = FolderNavigatorState(root: state.root, name: state.name, stack: state._stack.sublist(0, index).toList(growable: false));
    return true;
  }

  void push(String id, String name) {
    state = FolderNavigatorState(root: state.root, name: state.name, stack: [...state._stack, (id, name)]);
  }
}
