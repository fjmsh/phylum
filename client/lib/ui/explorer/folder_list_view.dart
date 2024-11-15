import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/resource_options_dialog.dart';
import 'package:provider/provider.dart';

import 'explorer_actions.dart';
import 'explorer_view_controller.dart';
import 'resource_details_row.dart';

class FolderListView extends StatefulWidget {
  const FolderListView({super.key});

  @override
  State<FolderListView> createState() => _FolderListViewState();
}

class _FolderListViewState extends State<FolderListView> {
  @override
  Widget build(BuildContext context) {
    final resources = context.select<ExplorerViewState, List<Resource>>((state) => state.resources);
    return ExplorerActions(
      child: Focus(
        autofocus: true,
        descendantsAreFocusable: false,
        child: ListTileTheme(
          data: ListTileThemeData(
            mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.basic),
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: ListView.builder(
            itemCount: resources.length,
            itemBuilder: (context, index) {
              final r = resources[index];
              bool deferHandling = false;
              return ResourceDetailsRow(
                  r: r,
                  onTapDown: (details) {
                    Focus.maybeOf(context)?.requestFocus();
                    final mode = HardwareKeyboard.instance.isControlPressed
                        ? SelectionMode.toggle
                        : HardwareKeyboard.instance.isShiftPressed
                            ? SelectionMode.range
                            : SelectionMode.single;
                    if (context.read<ExplorerViewState>().isSelected(r.id) && mode == SelectionMode.single) {
                      deferHandling = true;
                      context.read<ExplorerViewController>().updateSelection((_) => index, SelectionMode.noChange, false);
                    } else {
                      deferHandling = false;
                      context.read<ExplorerViewController>().updateSelection((_) => index, mode, false);
                    }
                  },
                  onTap: () {
                    if (deferHandling) {
                      context.read<ExplorerViewController>().updateSelection((_) => index, SelectionMode.single, false);
                    }
                  },
                  onSecondaryTapDown: (details) async {
                    ExplorerViewState state = context.read<ExplorerViewState>();
                    if (!state.isSelected(r.id)) {
                      final mode = HardwareKeyboard.instance.isShiftPressed || HardwareKeyboard.instance.isControlPressed
                          ? SelectionMode.add
                          : SelectionMode.single;
                      context.read<ExplorerViewController>().updateSelection((i) => index, mode, false);
                      state = context.read<ExplorerViewState>();
                    }
                    final position = RelativeRect.fromLTRB(
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                      details.globalPosition.dx,
                      details.globalPosition.dy,
                    );
                    final selection = await showMenu(
                      context: context,
                      position: position,
                      items: buildPopupMenuItems(context, state.selected).toList(growable: false),
                    );
                    if (context.mounted && selection != null) {
                      handleResourceOption(context, resources, selection);
                    }
                  },
                  onDoubleTap: () {
                    context.read<ExplorerViewController>().updateSelection((_) => index, SelectionMode.single, false);
                    Actions.maybeInvoke(context, const ActivateIntent());
                  });
            },
          ),
        ),
      ),
    );
  }
}
