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
        FocusUpIntent: CallbackAction<FocusUpIntent>(onInvoke: (i) {
          if (resources.isEmpty) return;
          final index = focusIndex == -1
              ? resources.length
              : focusIndex > 0
                  ? min(focusIndex - 1, resources.length)
                  : 0;
          updateFocus(index, i.mode);
          return null;
        }),
        FocusDownIntent: CallbackAction<FocusDownIntent>(onInvoke: (i) {
          if (resources.isEmpty) return;
          final index = min(focusIndex + 1, resources.length - 1);
          updateFocus(index, i.mode);
          return null;
        }),
        ToggleSelectionIntent: CallbackAction<ToggleSelectionIntent>(onInvoke: (i) {
          toggleSelection();
          return null;
        }),
        SelectAllIntent: CallbackAction<SelectAllIntent>(onInvoke: (i) {
          context.read<FolderSelectionManager>().setSelected(Set.of(resources.map((r) => r.id)));
          return null;
        }),
        ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(onInvoke: (i) {
          context.read<FolderSelectionManager>().setSelected(const {});
          return null;
        }),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) {
          context.read<FolderNavigatorStack>().pop();
          return null;
        }),
        OpenIntent: CallbackAction<OpenIntent>(onInvoke: (i) {
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
        child: ListView.builder(
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final r = resources[index];
            return Focus(
              focusNode: getFocusNode(r),
              child: ResourceDetailsRow(
                  r: r,
                  onTap: () {
                    final mode = HardwareKeyboard.instance.isControlPressed
                        ? SelectionMode.multi
                        : HardwareKeyboard.instance.isShiftPressed
                            ? SelectionMode.range
                            : SelectionMode.single;
                    updateFocus(index, mode);
                    if (mode == SelectionMode.multi) {
                      toggleSelection();
                    }
                  },
                  onDoubleTap: () => open(r)),
            );
          },
        ),
      ),
    );
  }

  void updateFocus(int index, SelectionMode mode) {
    switch (mode) {
      case SelectionMode.range:
        if (selectionStartIndex == -1) {
          selectionStartIndex = index;
        }
        final selected = Set.of(resources.getRange(min(selectionStartIndex, index), max(selectionStartIndex, index) + 1).map((r) => r.id));
        context.read<FolderSelectionManager>().setSelected(selected);
        break;
      case SelectionMode.single:
        context.read<FolderSelectionManager>().setSelected({resources[index].id});
        selectionStartIndex = index;
        break;
      case SelectionMode.multi:
        break;
    }
    getFocusNode(resources[index]).requestFocus();
    focusIndex = index;
  }

  void toggleSelection() {
    selectionStartIndex = context.read<FolderSelectionManager>().toggleSelected(resources[focusIndex].id) ? focusIndex : -1;
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

  FocusNode getFocusNode(Resource r) {
    return nodes.putIfAbsent(r.id, () => FocusNode(descendantsAreTraversable: false));
  }
}
