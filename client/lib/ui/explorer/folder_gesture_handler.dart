import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/menu/context_menu_helper.dart';
import 'package:phylum/ui/explorer/menu/menu_option.dart';
import 'package:phylum/ui/explorer/menu/option_groups.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';
import 'package:provider/provider.dart';

class FolderGestureHandler extends StatelessWidget {
  final Widget child;

  const FolderGestureHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ExplorerController>().updateSelection(
          (i) => i,
          SelectionMode.none,
          false,
        );
      },
      onSecondaryTapUp: (details) async {
        context.read<ExplorerController>().updateSelection(
          (i) => i,
          SelectionMode.none,
          false,
        );
        final state = context.read<ExplorerState>();
        final options = state.location.folderOptions;
        final resource = state.folder;
        if (options == null || resource == null) return;

        final resources = [resource];

        final groups = await getEnabledOptions(
          context.read(),
          options,
          resources,
        );
        if (!context.mounted) return;
        ContextMenuHelper.show(
          context: context,
          position: details.globalPosition,
          groups: groups,
          onOptionSelected: (option) {
            if (context.mounted) {
              handleOption(context, resources, option);
            }
          },
        );
      },
      child: child,
    );
  }
}
