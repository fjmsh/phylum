import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/resource_options_dialog.dart';
import 'package:provider/provider.dart';

class ResourceItemGestureHandler extends StatefulWidget {
  final int index;
  final Resource resource;
  final bool dropTargetActive;

  const ResourceItemGestureHandler({super.key, required this.index, required this.resource, required this.dropTargetActive});

  @override
  State<ResourceItemGestureHandler> createState() => _ResourceItemGestureHandlerState();
}

class _ResourceItemGestureHandlerState extends State<ResourceItemGestureHandler> {
  bool dropTargetActive = false;
  bool deferHandling = false;

  @override
  void initState() {
    super.initState();
    dropTargetActive = widget.dropTargetActive;
  }

  @override
  void didUpdateWidget(covariant ResourceItemGestureHandler oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (dropTargetActive != widget.dropTargetActive) {
      setState(() => dropTargetActive = widget.dropTargetActive);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        Focus.maybeOf(context)?.requestFocus();
        final mode = HardwareKeyboard.instance.isControlPressed
            ? SelectionMode.toggle
            : HardwareKeyboard.instance.isShiftPressed
                ? SelectionMode.range
                : SelectionMode.single;
        if (context.read<ExplorerViewState>().isSelected(widget.resource.id) && mode == SelectionMode.single) {
          deferHandling = true;
          context.read<ExplorerViewController>().updateSelection((_) => widget.index, SelectionMode.noChange, false);
        } else {
          deferHandling = false;
          context.read<ExplorerViewController>().updateSelection((_) => widget.index, mode, false);
        }
      },
      onTap: () {
        if (deferHandling) {
          deferHandling = false;
          context.read<ExplorerViewController>().updateSelection((_) => widget.index, SelectionMode.single, false);
        }
      },
      onSecondaryTapDown: (details) async {
        ExplorerViewState state = context.read<ExplorerViewState>();
        if (!state.isSelected(widget.resource.id)) {
          final mode =
              HardwareKeyboard.instance.isShiftPressed || HardwareKeyboard.instance.isControlPressed ? SelectionMode.add : SelectionMode.single;
          context.read<ExplorerViewController>().updateSelection((i) => widget.index, mode, false);
          state = context.read<ExplorerViewState>();
        }
        final position = RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        );
        final resources = state.selected;
        final selection = await showMenu(
          context: context,
          position: position,
          items: buildChildPopupMenuItems(context, resources).toList(growable: false),
        );
        if (context.mounted && selection != null) {
          handleResourceOption(context, resources, selection);
        }
      },
      onDoubleTap: () {
        context.read<ExplorerViewController>().updateSelection((_) => widget.index, SelectionMode.single, false);
        Actions.maybeInvoke(context, const ActivateIntent());
      },
      child: ResourceDraggable(
        resource: widget.resource,
        index: widget.index,
        dropTargetActive: dropTargetActive,
      ),
    );
  }
}
