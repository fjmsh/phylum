import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/navigation/explorer_controller.dart';
import 'package:phylum/ui/explorer/resource_details_row.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/ui/navigation/selection_mode.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

@pragma('vm:platform-const')
final bool _useSuperNative = defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS;

typedef DropWidgetBuilder = Widget Function(BuildContext context, bool dropTargetActive);

class ResourceDragTarget extends StatefulWidget {
  final String resourceId;

  final DropWidgetBuilder buildItem;

  ResourceDragTarget({required this.resourceId, required this.buildItem}) : super(key: ValueKey(resourceId));

  @override
  State<ResourceDragTarget> createState() => _ResourceDragTargetState();
}

class _ResourceDragTargetState extends State<ResourceDragTarget> {
  bool dropTargetActive = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget(
      builder: (context, candidate, rejected) => widget.buildItem(context, dropTargetActive),
      onWillAcceptWithDetails: (details) {
        final state = context.read<ExplorerState>();
        if (state.selectedIds.contains(widget.resourceId) || state.folder?.id == widget.resourceId) {
          // Don't accept drops into selected resources or the parent
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
        final selected = context.read<ExplorerState>().selected;
        for (final res in selected) {
          account.addAction(ResourceMoveAction(r: res, parent: widget.resourceId));
        }
        setState(() => dropTargetActive = false);
      },
    );
  }
}

class ExternalDropRegion extends StatefulWidget {
  final DropWidgetBuilder buildItem;

  const ExternalDropRegion({super.key, required this.buildItem});

  @override
  State<ExternalDropRegion> createState() => _ExternalDropRegionState();
}

class _ExternalDropRegionState extends State<ExternalDropRegion> {
  bool dropTargetActive = false;

  @override
  Widget build(BuildContext context) {
    return DropRegion(
      formats: Formats.standardFormats,
      child: widget.buildItem(context, dropTargetActive),
      onDropOver: (event) {
        if (event.session.items.isEmpty) return DropOperation.none;
        if (context.read<ExplorerState>().folderId == null) return DropOperation.none;
        for (final item in event.session.items) {
          if (kIsWeb || item.canProvide(Formats.fileUri)) {
            return DropOperation.copy;
          }
        }
        return DropOperation.none;
      },
      onDropEnter: (event) => setState(() => dropTargetActive = true),
      onDropLeave: (event) => setState(() => dropTargetActive = false),
      onPerformDrop: (event) async {
        final folderId = context.read<ExplorerState>().folderId;
        if (folderId == null) return;
        if (kIsWeb) {
          for (final item in event.session.items) {
            final reader = item.dataReader;

            if (reader != null) {
              final rawReader = reader.rawReader;
              if (rawReader != null) {
                final (entryFuture, _) = rawReader.getDataForFormat("web:entry");
                final entry = (await entryFuture) as dynamic;
                if (entry != null && !entry.isDirectory) {
                  reader.getFile(null, (file) {
                    debugPrint(file.fileName);
                    debugPrint(file.fileSize.toString());
                  }, onError: (err) {
                    debugPrint(err.toString());
                  });
                }
              }
            }
          }
        } else {
          final paths = <String>[];
          for (final item in event.session.items) {
            final reader = item.dataReader;
            if (reader != null) {
              final c = Completer<String?>();
              reader.getValue(
                Formats.fileUri,
                (value) => c.complete(value?.toFilePath(windows: Platform.isWindows)),
                onError: (value) => c.complete(null),
              );
              final path = await c.future;
              if (path != null) {
                paths.add(path);
              }
            }
          }
          if (context.mounted) {
            uploadRecursive(context, folderId, paths);
          }
        }
        setState(() => dropTargetActive = false);
      },
    );
  }
}

class ResourceDraggable extends StatelessWidget {
  final int index;
  final Resource resource;
  final bool dropTargetActive;

  const ResourceDraggable({super.key, required this.resource, required this.index, required this.dropTargetActive});

  @override
  Widget build(BuildContext context) {
    return Draggable(
      data: '__selected',
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () {
        final controller = context.read<ExplorerController>();
        if (!context.read<ExplorerState>().isSelected(resource.id)) {
          controller.updateSelection((_) => index, SelectionMode.single, false);
        }
        controller.setDragging(true);
      },
      onDragEnd: (details) {
        context.read<ExplorerController>().setDragging(false);
      },
      feedback: Builder(builder: (ctx) {
        final theme = Theme.of(context);
        final count = context.read<ExplorerState>().selectedIds.length;
        return Card(
          shape: RoundedRectangleBorder(side: BorderSide(color: theme.colorScheme.primary), borderRadius: BorderRadius.circular(4.0)),
          elevation: 16.0,
          margin: const EdgeInsets.only(left: 16.0),
          child: SizedBox(
            width: 240,
            height: 48,
            child: ListTile(
              leading: resource.getIcon(),
              title: Text(
                resource.name,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
              trailing: count == 1 ? null : Badge(label: Text(count.toString(), style: const TextStyle(fontSize: 14))),
            ),
          ),
        );
      }),
      child: ResourceDetailsRow(
        r: resource,
        dropTargetActive: dropTargetActive,
      ),
    );
  }
}
