import 'package:state_notifier/state_notifier.dart';

class FolderSelectionState {
  final Set<String> selected;
  final String focusId;
  final bool showFocus;
  final bool dragging;

  FolderSelectionState({required this.selected, required this.focusId, required this.showFocus, required this.dragging});

  bool isSelected(String id) {
    return selected.contains(id);
  }
}

class FolderSelectionManager extends StateNotifier<FolderSelectionState> {
  FolderSelectionManager() : super(FolderSelectionState(selected: {}, focusId: "", showFocus: false, dragging: false));

  void update({
    Set<String>? selected,
    String? focusId,
    bool? showFocus,
    bool? dragging,
  }) {
    state = FolderSelectionState(
        selected: selected ?? state.selected,
        focusId: focusId ?? state.focusId,
        showFocus: showFocus ?? state.showFocus,
        dragging: dragging ?? state.dragging);
  }
}
