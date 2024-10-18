import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

import 'explorer_view_controller.dart';
import 'resource_options_dialog.dart';

const _draggableDataSelected = '__selected';

class ResourceDetailsRow extends StatefulWidget {
  final Resource r;
  final Function(TapDownDetails)? onTapDown;
  final Function()? onTap;
  final Function()? onDoubleTap;
  final Function()? onSecondaryTap;

  ResourceDetailsRow({required this.r, this.onTapDown, this.onTap, this.onDoubleTap, this.onSecondaryTap}) : super(key: ValueKey(r.id));

  @override
  State<ResourceDetailsRow> createState() => _ResourceDetailsRowState();
}

class _ResourceDetailsRowState extends State<ResourceDetailsRow> {
  bool dropTargetActive = false;
  @override
  Widget build(BuildContext context) {
    return widget.r.dir
        ? DragTarget(
            builder: (context, candidate, rejected) => buildRow(context),
            onWillAcceptWithDetails: (details) {
              if (details.data == _draggableDataSelected && context.read<ExplorerViewState>().selectedIds.contains(widget.r.id)) {
                return false;
              }
              dropTargetActive = true;
              return true;
            },
            onLeave: (data) {
              dropTargetActive = false;
            },
            onAcceptWithDetails: (details) async {
              if (details.data == _draggableDataSelected) {
                final account = context.read<PhylumAccount>();
                final selected = context.read<ExplorerViewState>().selected;
                for (final res in selected) {
                  account.addAction(ResourceMoveAction(r: res, parent: widget.r));
                }
              }
              dropTargetActive = false;
            },
          )
        : buildRow(context);
  }

  Widget buildRow(BuildContext context) {
    return Draggable(
      data: _draggableDataSelected,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () {
        context.read<ExplorerViewController>().setDragging(true);
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
      child: GestureDetector(
        onTapDown: widget.onTapDown,
        onTap: widget.onTap,
        onDoubleTap: widget.onDoubleTap,
        onSecondaryTap: widget.onSecondaryTap,
        child: buildListTile(context),
      ),
    );
  }

  Widget buildListTile(BuildContext context) {
    final showBorder = context.select<ExplorerViewState, bool>((state) => state.focusId == widget.r.id && state.showFocus);
    final highlight = context.select<ExplorerViewState, bool>((state) => state.isSelected(widget.r.id));
    final dim = context.select<ExplorerViewState, bool>((state) => state.isSelected(widget.r.id) && state.dragging);
    final theme = Theme.of(context);
    final border = dropTargetActive
        ? BorderSide(color: theme.colorScheme.secondary, width: 2.0)
        : showBorder
            ? BorderSide(color: theme.colorScheme.primary, width: 2.0)
            : const BorderSide(color: Colors.transparent, width: 2.0);

    return ListTile(
      leading: widget.r.getIcon(),
      title: Text(widget.r.name),
      trailing: ResourceOptionsButton(r: widget.r),
      shape: RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(4.0)),
      selected: highlight,
      selectedColor: dim ? theme.colorScheme.primary.withOpacity(0.75) : null,
      selectedTileColor: dim ? theme.colorScheme.primaryContainer.withOpacity(0.75) : null,
      tileColor: dropTargetActive ? theme.colorScheme.secondaryContainer : null,
    );
  }
}

extension ResourceViewExtensions on Resource {
  Icon getIcon() {
    if (dir) return const Icon(Icons.folder);

    if (contentType.startsWith("image")) {
      return const Icon(Icons.image);
    } else if (contentType.startsWith("video")) {
      return const Icon(Icons.movie);
    } else if (contentType.startsWith("audio")) {
      return const Icon(Icons.headphones);
    } else if (contentType.startsWith("text")) {
      return const Icon(Icons.article);
    }
    return const Icon(Icons.insert_drive_file);
  }
}
