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
    final focussed = Focus.isAt(context);
    final selected = context.select<FolderSelectionState, bool>((state) => state.isSelected(r.id));

    final theme = Theme.of(context);
    final border = focussed ? BorderSide(color: theme.colorScheme.primary, width: 2.0) : const BorderSide(color: Colors.transparent, width: 2.0);
    return GestureDetector(
        onTapDown: (details) => onTap?.call(),
        onDoubleTap: () => onDoubleTap?.call(),
        onSecondaryTap: () => onSecondaryTap?.call(),
        child: ListTile(
          leading: r.getIcon(),
          title: Text(r.name),
          trailing: ResourceOptionsButton(r: r),
          shape: RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(4.0)),
          selected: selected,
        ));
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
