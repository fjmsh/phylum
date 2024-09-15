import 'dart:async';
import 'dart:math';

import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:state_notifier/state_notifier.dart';

class ExplorerViewState {
  final Resource? folder;
  final List<Resource> resources;
  final Set<String> selectedIds;
  final int focusIndex;
  final bool showFocus;
  final int selectionStartIndex;
  final bool dragging;
  final bool refreshing;
  final bool refreshError;

  String get focusId => (focusIndex < 0 || focusIndex >= resources.length) ? '' : resources[focusIndex].id;
  Iterable<Resource> get selected => resources.where((r) => selectedIds.contains(r.id));
  Resource? get selectedSingle => selectedIds.length != 1 ? null : resources.where((r) => selectedIds.contains(r.id)).firstOrNull;

  const ExplorerViewState({
    this.folder,
    this.resources = const [],
    this.selectedIds = const {},
    this.focusIndex = -1,
    this.showFocus = false,
    this.selectionStartIndex = -1,
    this.dragging = false,
    this.refreshing = false,
    this.refreshError = false,
  });

  ExplorerViewState copyWith({
    Resource? folder,
    List<Resource>? resources,
    Set<String>? selectedIds,
    int? focusIndex,
    bool? showFocus,
    int? selectionStartIndex,
    bool? dragging,
    bool? refreshing,
    bool? refreshError,
  }) =>
      ExplorerViewState(
        folder: folder ?? this.folder,
        resources: resources ?? this.resources,
        selectedIds: selectedIds ?? this.selectedIds,
        focusIndex: focusIndex ?? this.focusIndex,
        showFocus: showFocus ?? this.showFocus,
        selectionStartIndex: selectionStartIndex ?? this.selectionStartIndex,
        refreshing: refreshing ?? this.refreshing,
        refreshError: refreshError ?? this.refreshError,
      );

  bool isSelected(String id) {
    return selectedIds.contains(id);
  }
}

class ExplorerViewController extends StateNotifier<ExplorerViewState> {
  final PhylumAccount account;
  final String folderId;
  late final StreamSubscription<Resource?> folderSubscription;
  late final StreamSubscription<List<Resource>> childrenSubscription;

  ExplorerViewController({required this.account, required this.folderId}) : super(const ExplorerViewState()) {
    folderSubscription = account.resourceRepository.watchResource(folderId).listen((e) => state = state.copyWith(folder: e));
    childrenSubscription = account.resourceRepository.watchChildren(folderId).listen((e) => _updateResourceList(e));
    refresh();
  }

  void _updateResourceList(List<Resource> resources) {
    final extras = Set.of(state.selectedIds);
    extras.removeAll(state.resources.map((r) => r.id));
    final selectedIds = Set.of(state.selectedIds);
    selectedIds.removeAll(extras);

    // selection.
    final focusIndex = resources.indexWhere((r) => r.id == state.focusId);

    state = state.copyWith(
      resources: resources,
      focusIndex: focusIndex,
      selectedIds: selectedIds,
    );
  }

  @override
  void dispose() {
    folderSubscription.cancel();
    childrenSubscription.cancel();
    super.dispose();
  }

  void setDragging(bool dragging) {
    state = state.copyWith(dragging: dragging);
  }

  void selectAll({required bool showFocus}) {
    state = state.copyWith(selectedIds: Set.of(state.resources.map((r) => r.id)), showFocus: showFocus);
  }

  void updateSelection(int Function(int) indexFn, SelectionMode mode, bool highlight) {
    Set<String>? selectedIds;
    int index = indexFn(state.focusIndex);
    index = min(state.resources.length - 1, max(0, index));
    int selectionStartIndex = state.selectionStartIndex;
    switch (mode) {
      case SelectionMode.range:
        if (selectionStartIndex == -1) {
          selectionStartIndex = index;
        }
        selectedIds = Set.of(state.resources.getRange(min(selectionStartIndex, index), max(selectionStartIndex, index) + 1).map((r) => r.id));
        break;
      case SelectionMode.single:
        selectedIds = {state.resources[index].id};
        selectionStartIndex = index;
        break;
      case SelectionMode.toggle:
        selectedIds = Set.of(state.selectedIds);
        if (!selectedIds.add(state.resources[index].id)) {
          selectedIds.remove(state.resources[index].id);
        }
        selectionStartIndex = index;
        break;
      case SelectionMode.multi:
        break;
    }
    state = state.copyWith(
      selectedIds: selectedIds,
      focusIndex: index,
      showFocus: highlight,
    );
  }

  Future refresh() {
    if (state.refreshing) return Future.value(state);
    state = state.copyWith(refreshing: true);
    return account.resourceRepository.requestResource(folderId).then((result) => state = state.copyWith(
          refreshing: false,
          refreshError: result != null,
        ));
  }
}
