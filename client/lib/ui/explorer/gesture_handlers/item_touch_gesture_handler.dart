import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';
import 'package:provider/provider.dart';

class ItemTouchGestureHandler extends StatelessWidget {
  final Widget child;
  final int resourceIndex;

  ItemTouchGestureHandler({
    required String resourceId,
    required this.resourceIndex,
    required this.child,
  }) : super(key: ValueKey(resourceId));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      supportedDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      },
      onTap: () {
        if (context.read<ExplorerState>().selected.isEmpty) {
          final resource = context
              .read<ExplorerState>()
              .resources[resourceIndex];
          Actions.maybeInvoke(context, OpenResourceIntent(resource));
        } else {
          context.read<ExplorerController>().updateSelection(
            (_) => resourceIndex,
            SelectionMode.toggle,
            false,
          );
        }
      },
      onLongPress: () {
        context.read<ExplorerController>().updateSelection(
          (_) => resourceIndex,
          .add,
          false,
        );
      },
      child: child,
    );
  }
}
