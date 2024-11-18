import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/resource_options_dialog.dart';
import 'package:provider/provider.dart';

class ExplorerGestureHandler extends StatelessWidget {
  final Widget child;

  const ExplorerGestureHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        Actions.maybeInvoke(context, const DismissIntent());
      },
      onSecondaryTapDown: (details) async {
        Actions.maybeInvoke(context, const DismissIntent());
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
