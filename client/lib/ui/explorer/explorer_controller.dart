import 'dart:async';
import 'dart:math';

import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:state_notifier/state_notifier.dart';

import 'page.dart';
import 'selection_mode.dart';

class ExplorerState {
  final ExplorerPage page;
  final Resource? folder;
  final List<Resource> resources;
  final Set<String> selectedIds;
  final int focusIndex;
  final bool showFocus;
  final int selectionStartIndex;
  final bool dragging;
  final Future? refresh;
  final bool refreshError;

  String? get folderId => page is ExplorerPageFolder ? (page as ExplorerPageFolder).folderId : null;
  Resource? get focussed => focusIndex < 0 || focusIndex >= resources.length ? null : resources[focusIndex];
  String? get focusId => focussed?.id;
  Iterable<Resource> get selected => resources.where((r) => selectedIds.contains(r.id));
  Resource? get selectedSingle =>
      selectedIds.length != 1 ? null : resources.where((r) => selectedIds.contains(r.id)).first;
  Resource? get focussedIfSelected => selectedIds.isEmpty ? null : focussed;

  const ExplorerState({
    required this.page,
    this.folder,
    this.resources = const [],
    this.selectedIds = const {},
    this.focusIndex = -1,
    this.showFocus = false,
    this.selectionStartIndex = -1,
    this.dragging = false,
    this.refresh,
    this.refreshError = false,
  });

  ExplorerState copyWith({
    ExplorerPage? page,
    Resource? folder,
    List<Resource>? resources,
    Set<String>? selectedIds,
    int? focusIndex,
    bool? showFocus,
    int? selectionStartIndex,
    bool? dragging,
    Future? refresh,
    bool updateRefresh = false,
    bool? refreshError,
  }) =>
      ExplorerState(
        page: page ?? this.page,
        folder: folder ?? this.folder,
        resources: resources ?? this.resources,
        selectedIds: selectedIds ?? this.selectedIds,
        focusIndex: focusIndex ?? this.focusIndex,
        showFocus: showFocus ?? this.showFocus,
        selectionStartIndex: selectionStartIndex ?? this.selectionStartIndex,
        dragging: dragging ?? this.dragging,
        refresh: updateRefresh ? refresh : this.refresh,
        refreshError: refreshError ?? this.refreshError,
      );

  bool isSelected(String id) {
    return selectedIds.contains(id);
  }
}

class ExplorerController extends StateNotifier<ExplorerState> {
  final PhylumAccount _account;
  final PhylumRouterDelegate _routerDelegate;
  StreamSubscription<Resource?>? _folderSubscription;
  StreamSubscription<List<Resource>>? _childrenSubscription;

  ExplorerController({
    required PhylumAccount account,
    required PhylumRouterDelegate routerDelegate,
  })  : _account = account,
        _routerDelegate = routerDelegate,
        super(ExplorerState(page: routerDelegate.currentConfiguration!)) {
    _routerDelegate.addListener(updatePage);
    updatePage();
  }

  void updatePage() {
    final page = _routerDelegate.currentConfiguration!;
    _folderSubscription?.cancel();
    if (page is ExplorerPageFolder) {
      _folderSubscription = _account.db.watchResource(page.folderId).listen((e) => state = state.copyWith(folder: e));
      if (page.folderId != _account.userHome) {
        _account.db.markResourceAccess(page.folderId);
      }
    } else {
      _folderSubscription = null;
    }
    _childrenSubscription?.cancel();
    _childrenSubscription = page.items(_account).listen((e) => _updateResourceList(e));
    state = ExplorerState(page: page);
    refresh();
  }

  @override
  void dispose() {
    _routerDelegate.removeListener(updatePage);
    _folderSubscription?.cancel();
    _childrenSubscription?.cancel();
    super.dispose();
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

  void setDragging(bool dragging) {
    state = state.copyWith(dragging: dragging);
  }

  bool clearSelection() {
    if (state.selectedIds.isEmpty) return false;
    state = state.copyWith(
      selectedIds: const {},
      selectionStartIndex: state.selectionStartIndex,
      focusIndex: state.focusIndex,
      showFocus: false,
    );
    return true;
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
        selectedIds = Set.of(state.resources
            .getRange(min(selectionStartIndex, index), max(selectionStartIndex, index) + 1)
            .map((r) => r.id));
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
      case SelectionMode.all:
        selectedIds = Set.of(state.resources.map((r) => r.id));
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
    if (state.refresh != null) return state.refresh!;
    final c = Completer();
    state = state.copyWith(refresh: c.future, updateRefresh: true);
    state.page.refresh(_account).then((success) {
      c.complete();
      if (mounted) {
        state = state.copyWith(
          refresh: null,
          updateRefresh: true,
          refreshError: !success,
        );
      }
    }).onError((err, stack) {
      c.completeError(err!, stack);
    });
    return c.future;
  }
}
