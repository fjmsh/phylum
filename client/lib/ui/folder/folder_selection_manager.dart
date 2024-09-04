import 'package:state_notifier/state_notifier.dart';

class FolderSelectionState {
  final Set<String> selected;

  FolderSelectionState({required this.selected});

  bool isSelected(String id) {
    return selected.contains(id);
  }
}

class FolderSelectionManager extends StateNotifier<FolderSelectionState> {
  FolderSelectionManager() : super(FolderSelectionState(selected: {}));

  void setSelected(Set<String> ids) {
    state = FolderSelectionState(selected: ids);
  }

  bool toggleSelected(String id) {
    final selected = Set.of(state.selected);
    bool added = true;
    if (!selected.add(id)) {
      selected.remove(id);
      added = false;
    }
    state = FolderSelectionState(selected: selected);
    return added;
  }
}
