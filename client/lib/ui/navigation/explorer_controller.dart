import 'dart:async';
import 'dart:math';

import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:state_notifier/state_notifier.dart';

import 'destination.dart';
import 'history_manager.dart';

class ExplorerState {
  final String folderId;
  final Resource? folder;
  final List<Resource> resources;
  final Set<String> selectedIds;
  final int focusIndex;
  final bool showFocus;
  final int selectionStartIndex;
  final bool dragging;
  final bool refreshing;
  final bool refreshError;

  Resource? get focussed => focusIndex < 0 || focusIndex >= resources.length ? null : resources[focusIndex];
  String? get focusId => focussed?.id;
  Iterable<Resource> get selected => resources.where((r) => selectedIds.contains(r.id));
  Resource? get selectedSingle => selectedIds.length != 1 ? null : resources.where((r) => selectedIds.contains(r.id)).firstOrNull;
  Resource? get focussedIfSelected => selectedIds.isEmpty ? null : focussed;

  const ExplorerState({
    required this.folderId,
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

  ExplorerState copyWith({
    String? folderId,
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
      ExplorerState(
        folderId: folderId ?? this.folderId,
        folder: folder ?? this.folder,
        resources: resources ?? this.resources,
        selectedIds: selectedIds ?? this.selectedIds,
        focusIndex: focusIndex ?? this.focusIndex,
        showFocus: showFocus ?? this.showFocus,
        selectionStartIndex: selectionStartIndex ?? this.selectionStartIndex,
        dragging: dragging ?? this.dragging,
        refreshing: refreshing ?? this.refreshing,
        refreshError: refreshError ?? this.refreshError,
      );

  bool isSelected(String id) {
    return selectedIds.contains(id);
  }
}

class ExplorerController extends StateNotifier<ExplorerState> {
  final ResourceRepository _repository;
  final String _homeId;
  void Function()? removeHistoryManagerListener;
  StreamSubscription<Resource?>? _folderSubscription;
  StreamSubscription<List<Resource>>? _childrenSubscription;

  ExplorerController({
    required PhylumAccount account,
    NavHistoryManager? navHistoryManager,
    NavDestination? destination,
  })  : _repository = account.resourceRepository,
        _homeId = account.userHome,
        super(ExplorerState(folderId: '')) {
    removeHistoryManagerListener = navHistoryManager?.addListener((state) {
      updateDestination(state.current);
    }, fireImmediately: true);
    if (navHistoryManager == null) {
      updateDestination(destination!);
    }
  }

  void updateDestination(NavDestination destination) {
    String folderId = state.folderId;
    if (destination is NavDestinationFolder) {
      folderId = destination.folderId;
    } else if (destination is NavDestinationHome) {
      folderId = _homeId;
    }
    if (folderId == state.folderId) return;
    state = ExplorerState(folderId: folderId);
    refresh();
    _folderSubscription?.cancel();
    _childrenSubscription?.cancel();
    _folderSubscription = _repository.watchResource(folderId).listen((e) => state = state.copyWith(folder: e));
    _childrenSubscription = _repository.watchChildren(folderId).listen((e) => _updateResourceList(e));
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
    _folderSubscription?.cancel();
    _childrenSubscription?.cancel();
    super.dispose();
  }

  void setDragging(bool dragging) {
    state = state.copyWith(dragging: dragging);
  }

  void selectAll({required bool showFocus}) {
    state = state.copyWith(selectedIds: Set.of(state.resources.map((r) => r.id)), showFocus: showFocus);
  }

  void updateSelection(int Function(int)? indexFn, SelectionMode mode, bool highlight) {
    Set<String>? selectedIds;
    int index = indexFn?.call(state.focusIndex) ?? state.focusIndex;
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
      case SelectionMode.add:
        selectedIds = Set.of(state.selectedIds);
        selectedIds.add(state.resources[index].id);
        selectionStartIndex = index;
        break;
      case SelectionMode.none:
        selectedIds = const {};
        selectionStartIndex = index;
        break;
      case SelectionMode.noChange:
        break;
    }
    state = state.copyWith(
      selectedIds: selectedIds,
      selectionStartIndex: selectionStartIndex,
      focusIndex: index,
      showFocus: highlight,
    );
  }

  Future refresh() {
    if (state.refreshing) return Future.value(state);
    state = state.copyWith(refreshing: true);
    return _repository.requestResource(state.folderId).then((result) {
      if (mounted) {
        state = state.copyWith(
          refreshing: false,
          refreshError: !result.success,
        );
      }
    });
  }
}
