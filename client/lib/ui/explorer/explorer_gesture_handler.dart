import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/menu/menu_option.dart';
import 'package:phylum/ui/menu/option_groups.dart';
import 'package:provider/provider.dart';

class ExplorerGestureHandler extends StatelessWidget {
  final Widget child;

  const ExplorerGestureHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<ExplorerViewController>().updateSelection((i) => i, SelectionMode.none, false);
      },
      onSecondaryTapUp: (details) async {
        context.read<ExplorerViewController>().updateSelection((i) => i, SelectionMode.none, false);
        final resource = context.read<ExplorerViewState>().folder;
        if (resource == null) return;
        final position = RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        );
        final resources = [resource];
        final items = await buildPopupMenuItems(context.read<PhylumAccount>(), parentFolderOptions, resources);
        if (!context.mounted) return;
        final selection = await showMenu(
          context: context,
          position: position,
          items: items.toList(growable: false),
        );
        if (context.mounted && selection != null) {
          handleOption(context, resources, selection);
        }
      },
      child: child,
    );
  }
}
