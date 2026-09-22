import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/gesture_handlers/draggable_resource.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';
import 'package:phylum/ui/explorer/util/icon_extensions.dart';
import 'package:provider/provider.dart';

class DragHandler extends StatelessWidget {
  final int index;
  final Resource resource;
  final Widget Function() buildItem;

  const DragHandler({
    super.key,
    required this.resource,
    required this.index,
    required this.buildItem,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableResource(
      supportedDevices: {PointerDeviceKind.trackpad, PointerDeviceKind.mouse},
      data: resource.id,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => _onDragStarted(context),
      onDragEnd: (details) {
        context.read<ExplorerController>().setDragging(false);
      },
      feedback: _feedback(context),
      child: DraggableResource(
        // delay cannot be longer than 500, otherwise the long press select gesture recognizer will win
        // and this drag will be cancelled
        delay: const Duration(milliseconds: 600),
        supportedDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.invertedStylus,
          PointerDeviceKind.unknown,
        },
        hapticFeedbackOnStart: true,
        data: resource.id,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () => _onDragStarted(context),
        onDragEnd: (details) {
          context.read<ExplorerController>().setDragging(false);
        },
        feedback: _feedback(context),
        child: buildItem(),
      ),
    );
  }

  void _onDragStarted(BuildContext context) {
    final controller = context.read<ExplorerController>();
    if (!context.read<ExplorerState>().isSelected(resource.id)) {
      controller.updateSelection((_) => index, SelectionMode.single, false);
    }
    controller.setDragging(true);
  }

  Widget _feedback(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final theme = Theme.of(context);
        final count = context.read<ExplorerState>().selectedIds.length;
        return Card(
          shape: RoundedRectangleBorder(
            side: BorderSide(color: theme.colorScheme.primary),
            borderRadius: BorderRadius.circular(4.0),
          ),
          elevation: 16.0,
          margin: const EdgeInsets.only(left: 16.0),
          child: SizedBox(
            width: 240,
            height: 48,
            child: ListTile(
              leading: resource.getIcon(context.read()),
              title: Text(
                resource.name,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
              trailing: count == 1
                  ? null
                  : Badge(
                      label: Text(
                        count.toString(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
