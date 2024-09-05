import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/folder/folder_selection_manager.dart';
import 'package:phylum/ui/folder/resource_options_dialog.dart';
import 'package:provider/provider.dart';

class ResourceDetailsRow extends StatelessWidget {
  final Resource r;
  final Function()? onTap;
  final Function()? onDoubleTap;
  final Function()? onSecondaryTap;

  ResourceDetailsRow({required this.r, this.onTap, this.onDoubleTap, this.onSecondaryTap}) : super(key: ValueKey(r.id));

  @override
  Widget build(BuildContext context) {
    return r.dir
        ? DragTarget(
            builder: (context, candidate, rejected) => buildRow(context),
            onWillAcceptWithDetails: (details) {
              return true;
            },
            onLeave: (data) {},
            onAcceptWithDetails: (details) {
              print(details.data);
            },
          )
        : buildRow(context);
  }

  Widget buildRow(BuildContext context) {
    final focussed = Focus.isAt(context);
    final selected = context.select<FolderSelectionState, bool>((state) => state.isSelected(r.id));

    return Draggable(
      data: r,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Builder(builder: (context) {
        final theme = Theme.of(context);
        return Card(
          shape: RoundedRectangleBorder(side: BorderSide(color: theme.colorScheme.primary), borderRadius: BorderRadius.circular(4.0)),
          elevation: 16.0,
          margin: const EdgeInsets.only(left: 16.0),
          child: SizedBox(
            width: 240,
            height: 48,
            child: ListTile(
              leading: r.getIcon(),
              title: Text(r.name),
            ),
          ),
        );
      }),
      childWhenDragging: Builder(builder: (context) {
        return Opacity(opacity: 0.5, child: buildListTile(context, focussed, selected));
      }),
      child: GestureDetector(
        onTapDown: selected ? null : (details) => onTap?.call(),
        onTap: selected ? () => onTap?.call() : null,
        onDoubleTap: () => onDoubleTap?.call(),
        onSecondaryTap: () => onSecondaryTap?.call(),
        child: buildListTile(context, focussed, selected),
      ),
    );
  }

  Widget buildListTile(BuildContext context, bool showBorder, bool highlight) {
    final theme = Theme.of(context);
    final border = showBorder ? BorderSide(color: theme.colorScheme.primary, width: 2.0) : const BorderSide(color: Colors.transparent, width: 2.0);

    return ListTile(
      leading: r.getIcon(),
      title: Text(r.name),
      trailing: ResourceOptionsButton(r: r),
      shape: RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(4.0)),
      selected: highlight,
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
