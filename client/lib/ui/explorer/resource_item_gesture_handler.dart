import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/resource_details_row.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/ui/explorer/resource_options_dialog.dart';
import 'package:provider/provider.dart';

class ResourceItemGestureHandler extends StatefulWidget {
  final int index;
  final Resource r;

  const ResourceItemGestureHandler({super.key, required this.index, required this.r});

  @override
  State<ResourceItemGestureHandler> createState() => _ResourceItemGestureHandlerState();
}

class _ResourceItemGestureHandlerState extends State<ResourceItemGestureHandler> {
  bool dropTargetActive = false;
  bool deferHandling = false;

  @override
  Widget build(BuildContext context) {
    return widget.r.dir
        ? DragTarget(
            builder: (context, candidate, rejected) => buildGestureDetector(context),
            onWillAcceptWithDetails: (details) {
              if (context.read<ExplorerViewState>().selectedIds.contains(widget.r.id)) {
                return false;
              }
              setState(() => dropTargetActive = true);
              return true;
            },
            onLeave: (data) {
              setState(() => dropTargetActive = false);
            },
            onAcceptWithDetails: (details) async {
              final account = context.read<PhylumAccount>();
              final selected = context.read<ExplorerViewState>().selected;
              for (final res in selected) {
                account.addAction(ResourceMoveAction(r: res, parent: widget.r));
              }
              setState(() => dropTargetActive = false);
            },
          )
        : buildGestureDetector(context);
  }

  Widget buildGestureDetector(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        Focus.maybeOf(context)?.requestFocus();
        final mode = HardwareKeyboard.instance.isControlPressed
            ? SelectionMode.toggle
            : HardwareKeyboard.instance.isShiftPressed
                ? SelectionMode.range
                : SelectionMode.single;
        if (context.read<ExplorerViewState>().isSelected(widget.r.id) && mode == SelectionMode.single) {
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
        if (!state.isSelected(widget.r.id)) {
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
          items: buildPopupMenuItems(context, resources).toList(growable: false),
        );
        if (context.mounted && selection != null) {
          handleResourceOption(context, resources, selection);
        }
      },
      onDoubleTap: () {
        context.read<ExplorerViewController>().updateSelection((_) => widget.index, SelectionMode.single, false);
        Actions.maybeInvoke(context, const ActivateIntent());
      },
      child: Draggable(
        data: '__selected',
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: () {
          final controller = context.read<ExplorerViewController>();
          if (!context.read<ExplorerViewState>().isSelected(widget.r.id)) {
            controller.updateSelection((_) => widget.index, SelectionMode.single, false);
          }
          controller.setDragging(true);
        },
        onDragEnd: (details) {
          context.read<ExplorerViewController>().setDragging(false);
        },
        feedback: Builder(builder: (ctx) {
          final theme = Theme.of(context);
          final count = context.read<ExplorerViewState>().selectedIds.length;
          return Card(
            shape: RoundedRectangleBorder(side: BorderSide(color: theme.colorScheme.primary), borderRadius: BorderRadius.circular(4.0)),
            elevation: 16.0,
            margin: const EdgeInsets.only(left: 16.0),
            child: SizedBox(
              width: 240,
              height: 48,
              child: ListTile(
                leading: widget.r.getIcon(),
                title: Text(widget.r.name),
                trailing: count == 1 ? null : Badge(label: Text(count.toString(), style: const TextStyle(fontSize: 14))),
              ),
            ),
          );
        }),
        child: ResourceDetailsRow(
          r: widget.r,
          dropTargetActive: dropTargetActive,
        ),
      ),
    );
  }
}
