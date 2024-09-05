import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/folder/folder_selection_manager.dart';
import 'package:phylum/ui/folder/resource_options_dialog.dart';
import 'package:provider/provider.dart';

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
              dropTargetActive = true;
              return true;
            },
            onLeave: (data) {
              dropTargetActive = false;
            },
            onAcceptWithDetails: (details) {
              dropTargetActive = false;
              print(details.data);
            },
          )
        : buildRow(context);
  }

  Widget buildRow(BuildContext context) {
    return Draggable(
      data: widget.r,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () {
        context.read<FolderSelectionManager>().update(dragging: true);
      },
      onDragEnd: (details) {
        context.read<FolderSelectionManager>().update(dragging: false);
      },
      feedback: Builder(builder: (ctx) {
        final theme = Theme.of(context);
        final count = context.read<FolderSelectionState>().selected.length;
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
    final showBorder = context.select<FolderSelectionState, bool>((state) => state.focusId == widget.r.id && state.showFocus);
    final highlight = context.select<FolderSelectionState, bool>((state) => state.isSelected(widget.r.id));
    final dim = context.select<FolderSelectionState, bool>((state) => state.isSelected(widget.r.id) && state.dragging);
    final theme = Theme.of(context);
    final border = dropTargetActive
        ? BorderSide(color: theme.colorScheme.secondary, width: 2.0)
        : showBorder
            ? BorderSide(color: theme.colorScheme.primary, width: 2.0)
            : const BorderSide(color: Colors.transparent, width: 2.0);

    return Opacity(
      opacity: dim ? 0.6 : 1.0,
      child: ListTile(
        leading: widget.r.getIcon(),
        title: Text(widget.r.name),
        trailing: ResourceOptionsButton(r: widget.r),
        shape: RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(4.0)),
        selected: highlight,
        selectedTileColor: dim ? theme.colorScheme.surfaceDim : null,
        tileColor: dropTargetActive ? theme.colorScheme.secondaryContainer : null,
      ),
    );
  }
}

extension ResourceViewExtensions on Resource {
  Icon getIcon() {
    if (dir) return const Icon(Icons.folder);
    final index = name.lastIndexOf('.');
    final ext = index > 0 ? name.substring(index + 1).toLowerCase() : '';
    return switch (ext) {
      'bmp' || 'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'heic' || 'heif' || 'svg' => const Icon(Icons.image),
      'webm' || 'avi' || 'mp4' || 'mov' => const Icon(Icons.movie),
      'mp3' || 'mp4' || 'm4a' || 'ogg' || 'oga' => const Icon(Icons.headphones),
      'txt' || 'csv' => const Icon(Icons.article),
      _ => const Icon(Icons.insert_drive_file),
    };
  }
}
