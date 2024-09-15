import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
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
                    context.read<ExplorerViewController>().updateSelection((_) => index, SelectionMode.multi, false);
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
                onDoubleTap: () {
                  context.read<ExplorerViewController>().updateSelection((_) => index, SelectionMode.single, false);
                  Actions.maybeInvoke(context, const ActivateIntent());
                });
          },
        ),
      ),
    );
  }
}
