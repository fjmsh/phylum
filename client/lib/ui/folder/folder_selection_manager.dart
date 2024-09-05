import 'package:state_notifier/state_notifier.dart';

class FolderSelectionState {
  final Set<String> selected;
  final String focusId;
  final int focusIndex;
  final bool showFocus;
  final bool dragging;

  FolderSelectionState({required this.selected, required this.focusId, required this.focusIndex, required this.showFocus, required this.dragging});

  bool isSelected(String id) {
    return selected.contains(id);
  }
}

class FolderSelectionManager extends StateNotifier<FolderSelectionState> {
  FolderSelectionManager() : super(FolderSelectionState(selected: {}, focusId: "", focusIndex: -1, showFocus: false, dragging: false));

  void update({
    Set<String>? selected,
    String? focusId,
    int? focusIndex,
    bool? showFocus,
    bool? dragging,
  }) {
    state = FolderSelectionState(
        selected: selected ?? state.selected,
        focusId: focusId ?? state.focusId,
        focusIndex: focusIndex ?? state.focusIndex,
        showFocus: showFocus ?? state.showFocus,
        dragging: dragging ?? state.dragging);
  }
}
