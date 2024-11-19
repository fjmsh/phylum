import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/menu_options.dart';
import 'package:provider/provider.dart';

class ExplorerGestureHandler extends StatelessWidget {
  final Widget child;

  const ExplorerGestureHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        context.read<ExplorerViewController>().updateSelection((i) => i, SelectionMode.none, false);
      },
      onSecondaryTapDown: (details) async {
        context.read<ExplorerViewController>().updateSelection((i) => i, SelectionMode.none, false);
        final resource = context.read<ExplorerViewState>().folder;
        if (resource == null) return;
        final position = RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        );
        final selection = await showMenu(
          context: context,
          position: position,
          items: buildExplorerPopupMenuItems(context, [resource]).toList(growable: false),
        );
        if (context.mounted && selection != null) {
          handleResourceOption(context, [resource], selection);
        }
      },
      child: child,
    );
  }
}
