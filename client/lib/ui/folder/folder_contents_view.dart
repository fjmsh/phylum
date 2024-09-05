import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/folder/folder_navigator_stack.dart';
import 'package:phylum/ui/folder/folder_selection_manager.dart';
import 'package:phylum/ui/folder/resource_details_row.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class FolderContentsView extends StatefulWidget {
  final List<Resource> resources;

  const FolderContentsView({super.key, required this.resources});

  @override
  State<FolderContentsView> createState() => _FolderContentsViewState();
}

class _FolderContentsViewState extends State<FolderContentsView> {
  final Map<String, FocusNode> nodes = {};
  late List<Resource> resources;
  int focusIndex = -1;
  int selectionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    resources = widget.resources;
  }

  @override
  void didUpdateWidget(covariant FolderContentsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selection = context.read<FolderSelectionState>();

    final extras = Set.of(selection.selected);
    extras.removeAll(widget.resources);
    final selected = Set.of(selection.selected);
    selected.removeAll(extras);

    // selection.
    focusIndex = widget.resources.indexWhere((r) => r.id == selection.focusId);
    WidgetsBinding.instance.addPostFrameCallback((duration) => context.read<FolderSelectionManager>().update(
          focusId: focusIndex == -1 ? "" : null,
          selected: selected,
        ));

    setState(() => resources = widget.resources);
  }

  @override
  void dispose() {
    for (final n in nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
        FocusUpIntent: CallbackAction<FocusUpIntent>(onInvoke: (i) {
          if (resources.isEmpty) return;
          final index = focusIndex == -1
              ? resources.length
              : focusIndex > 0
                  ? min(focusIndex - 1, resources.length)
                  : 0;
          updateSelection(index, i.mode, true);
          return null;
        }),
        FocusDownIntent: CallbackAction<FocusDownIntent>(onInvoke: (i) {
          if (resources.isEmpty) return;
          final index = min(focusIndex + 1, resources.length - 1);
          updateSelection(index, i.mode, true);
          return null;
        }),
        ToggleSelectionIntent: CallbackAction<ToggleSelectionIntent>(onInvoke: (i) {
          updateSelection(focusIndex, SelectionMode.toggle, true);
          return null;
        }),
        SelectAllIntent: CallbackAction<SelectAllIntent>(onInvoke: (i) {
          context.read<FolderSelectionManager>().update(selected: Set.of(resources.map((r) => r.id)), showFocus: true);
          return null;
        }),
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) {
          if (focusIndex >= 0) {
            updateSelection(focusIndex, SelectionMode.single, true);
          } else {
            context.read<FolderSelectionManager>().update(selected: const {}, showFocus: true);
          }
          return null;
        }),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) {
          context.read<FolderNavigatorStack>().pop();
          return null;
        }),
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (i) {
          open(resources[focusIndex]);
          return null;
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (i) {
          deleteSelected();
          return null;
        }),
      },
      child: Focus(
        autofocus: true,
        descendantsAreFocusable: false,
        child: ListView.builder(
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final r = resources[index];
            bool deferHandling = false;
            return ResourceDetailsRow(
                r: r,
                onTapDown: (details) {
                  final mode = HardwareKeyboard.instance.isControlPressed
                      ? SelectionMode.toggle
                      : HardwareKeyboard.instance.isShiftPressed
                          ? SelectionMode.range
                          : SelectionMode.single;
                  if (context.read<FolderSelectionState>().isSelected(r.id) && mode == SelectionMode.single) {
                    deferHandling = true;
                    context.read<FolderSelectionManager>().update(focusId: r.id, showFocus: false);
                  } else {
                    deferHandling = false;
                    updateSelection(index, mode, false);
                  }
                },
                onTap: () {
                  if (deferHandling) {
                    updateSelection(index, SelectionMode.single, false);
                  }
                },
                onDoubleTap: () => open(r));
          },
        ),
      ),
    );
  }

  void updateSelection(int index, SelectionMode mode, bool highlight) {
    Set<String>? selected;
    switch (mode) {
      case SelectionMode.range:
        if (selectionStartIndex == -1) {
          selectionStartIndex = index;
        }
        selected = Set.of(resources.getRange(min(selectionStartIndex, index), max(selectionStartIndex, index) + 1).map((r) => r.id));
        break;
      case SelectionMode.single:
        selected = {resources[index].id};
        selectionStartIndex = index;
        break;
      case SelectionMode.toggle:
        selected = Set.of(context.read<FolderSelectionState>().selected);
        if (!selected.add(resources[index].id)) {
          selected.remove(resources[index].id);
        }
        selectionStartIndex = index;
        break;
      case SelectionMode.multi:
        break;
    }
    focusIndex = index;
    context
        .read<FolderSelectionManager>()
        .update(selected: selected, focusId: index < resources.length ? resources[index].id : null, showFocus: highlight);
  }

  void open(Resource r) {
    if (r.dir) context.read<FolderNavigatorStack>().push(r.id, r.name);
  }

  void deleteSelected() async {
    final selectedIds = context.read<FolderSelectionState>().selected;
    if (selectedIds.isEmpty) return;
    final account = context.read<PhylumAccount>();
    final selected = resources.where((r) => selectedIds.contains(r.id)).toList(growable: false);
    final confirm = await showAlertDialog(context,
            title: 'Delete ${selectedIds.length} files?', barrierDismissible: true, positiveText: 'YES', negativeText: 'NO') ??
        false;

    if (!confirm) return;
    for (final r in selected) {
      account.addAction(ResourceDeleteAction(r: r));
    }
  }
}
