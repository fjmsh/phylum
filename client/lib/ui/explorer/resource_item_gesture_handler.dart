import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/menu/menu_option.dart';
import 'package:phylum/ui/explorer/menu/option_groups.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';
import 'package:provider/provider.dart';

class ResourceItemGestureHandler extends StatefulWidget {
  final int index;
  final Resource resource;
  final Widget Function() buildItem;

  const ResourceItemGestureHandler({
    super.key,
    required this.index,
    required this.resource,
    required this.buildItem,
  });

  @override
  State<ResourceItemGestureHandler> createState() =>
      _ResourceItemGestureHandlerState();
}

class _ResourceItemGestureHandlerState
    extends State<ResourceItemGestureHandler> {
  bool deferHandling = false;

  @override
  Widget build(BuildContext context) {
    return _TouchGestureHandler(
      resourceIndex: widget.index,
      child: _MouseGestureHandler(
        resourceId: widget.resource.id,
        resourceIndex: widget.index,
        child: ResourceDraggable(
          resource: widget.resource,
          index: widget.index,
          buildItem: widget.buildItem,
        ),
      ),
    );
  }
}

class _TouchGestureHandler extends StatelessWidget {
  final Widget child;
  final int resourceIndex;

  const _TouchGestureHandler({
    required this.resourceIndex,
    required this.child,
  });

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
          _openResource(context, resourceIndex);
        } else {
          context.read<ExplorerController>().updateSelection(
            (_) => resourceIndex,
            SelectionMode.toggle,
            false,
          );
        }
      },
      onLongPress:
          context.select<ExplorerState, bool>(
            (state) => state.selected.isNotEmpty,
          )
          ? null
          : () {
              context.read<ExplorerController>().updateSelection(
                (_) => resourceIndex,
                SelectionMode.single,
                false,
              );
            },
    );
  }
}

class _MouseGestureHandler extends StatefulWidget {
  final int resourceIndex;
  final String resourceId;
  final Widget child;

  const _MouseGestureHandler({
    required this.resourceIndex,
    required this.resourceId,
    required this.child,
  }) : super();

  @override
  State<_MouseGestureHandler> createState() => _MouseGestureHandlerState();
}

class _MouseGestureHandlerState extends State<_MouseGestureHandler> {
  bool deferHandling = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      supportedDevices: {PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
      onTapDown: (details) {
        Focus.maybeOf(context)?.requestFocus();
        final mode = HardwareKeyboard.instance.isControlPressed
            ? SelectionMode.toggle
            : HardwareKeyboard.instance.isShiftPressed
            ? SelectionMode.range
            : SelectionMode.single;
        if (context.read<ExplorerState>().isSelected(widget.resourceId) &&
            mode == SelectionMode.single) {
          deferHandling = true;
          context.read<ExplorerController>().updateSelection(
            (_) => widget.resourceIndex,
            SelectionMode.noChange,
            false,
          );
        } else {
          deferHandling = false;
          context.read<ExplorerController>().updateSelection(
            (_) => widget.resourceIndex,
            mode,
            false,
          );
        }
      },
      onTap: () {
        if (deferHandling) {
          deferHandling = false;
          context.read<ExplorerController>().updateSelection(
            (_) => widget.resourceIndex,
            SelectionMode.single,
            false,
          );
        }
      },
      onSecondaryTapUp: (details) async {
        ExplorerState state = context.read<ExplorerState>();
        if (!state.isSelected(widget.resourceId)) {
          final mode =
              HardwareKeyboard.instance.isShiftPressed ||
                  HardwareKeyboard.instance.isControlPressed
              ? SelectionMode.add
              : SelectionMode.single;
          context.read<ExplorerController>().updateSelection(
            (i) => widget.resourceIndex,
            mode,
            false,
          );
          state = context.read<ExplorerState>();
        } else {
          context.read<ExplorerController>().updateSelection(
            null,
            SelectionMode.noChange,
            false,
          );
        }
        final position = RelativeRect.fromLTRB(
          details.globalPosition.dx,
          details.globalPosition.dy,
          details.globalPosition.dx,
          details.globalPosition.dy,
        );
        final resources = state.selected;
        final options = state.location.selectedResourceOptions;
        final items = await buildPopupMenuItems(
          context.read<PhylumAccount>(),
          options,
          resources,
        );
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
      onDoubleTap: () => _openResource(context, widget.resourceIndex),
      child: widget.child,
    );
  }
}

void _openResource(BuildContext context, int index) {
  final resource = context.read<ExplorerState>().resources[index];
  Actions.maybeInvoke(context, OpenResourceIntent(resource));
}
