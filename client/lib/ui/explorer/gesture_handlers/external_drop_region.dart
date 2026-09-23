import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/util/upload/upload_utils.dart';
import 'package:provider/provider.dart';

import 'external_drop_handler_stub.dart'
    if (dart.library.ffi) 'external_drop_handler_io.dart';

class ExternalDropRegion extends StatefulWidget {
  final Function(BuildContext context, bool active) buildItem;

  const ExternalDropRegion({super.key, required this.buildItem});

  @override
  State<ExternalDropRegion> createState() => _ExternalDropRegionState();
}

class _ExternalDropRegionState extends State<ExternalDropRegion> {
  bool dropTargetActive = false;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (details) => setState(() => dropTargetActive = true),
      onDragExited: (details) => setState(() => dropTargetActive = false),
      onDragDone: (details) async {
        final folderId = context.read<ExplorerState>().folderId;
        if (folderId == null) return;
        DirTree tree = DirTree.empty();
        for (final item in details.files) {
          final bookmark = item.extraAppleBookmark;
          if (bookmark != null) {
            DesktopDrop.instance.startAccessingSecurityScopedResource(
              bookmark: bookmark,
            );
          }
          tree = tree.mergeWith(await enumerateDropItemPlatform(item));
          if (bookmark != null) {
            DesktopDrop.instance.stopAccessingSecurityScopedResource(
              bookmark: bookmark,
            );
          }
        }
        if (!context.mounted) return;
        uploadDirTree(context, folderId, tree);
      },
      child: widget.buildItem(context, dropTargetActive),
    );
  }
}

Future<DirTree> enumerateDropItem(DropItem item, String prefix) async {
  if (item is DropItemFile) {
    final size = await item.length();
    return Future.value(
      DirTree(
        totalSize: size,
        files: [
          UploadFile(
            size: size,
            stream: item.openRead(),
            path: '$prefix${item.name}',
          ),
        ],
        dirs: const [],
      ),
    );
  }
  if (item is DropItemDirectory) {
    DirTree tree = DirTree(
      totalSize: 0,
      dirs: ['$prefix${item.name}'],
      files: const [],
    );

    prefix = '$prefix${item.name}/';
    for (final file in item.children) {
      tree = tree.mergeWith(await enumerateDropItem(file, prefix));
    }

    return tree;
  }
  throw 'Unrecognized DropItem: $item';
}
