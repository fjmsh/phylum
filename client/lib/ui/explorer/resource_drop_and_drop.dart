import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/resource_details_row.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

@pragma('vm:platform-const')
final bool _useSuperNative = !Platform.isAndroid && !Platform.isIOS;

class ResourceDropTarget extends StatefulWidget {
  final String resourceId;

  final Widget Function(String resourceId, bool dropTargetActive) buildItem;

  ResourceDropTarget({required this.resourceId, required this.buildItem}) : super(key: ValueKey(resourceId));

  @override
  State<ResourceDropTarget> createState() => _ResourceDropTargetState();
}

class _ResourceDropTargetState extends State<ResourceDropTarget> {
  bool dropTargetActive = false;

  @override
  Widget build(BuildContext context) {
    return _useSuperNative ? buildSuperDropRegion(context) : buildFlutterDragTarget(context);
  }

  Widget buildFlutterDragTarget(BuildContext context) {
    return DragTarget(
      builder: (context, candidate, rejected) => widget.buildItem(widget.resourceId, dropTargetActive),
      onWillAcceptWithDetails: (details) {
        final state = context.read<ExplorerViewState>();
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
        final selected = context.read<ExplorerViewState>().selected;
        for (final res in selected) {
          account.addAction(ResourceMoveAction(r: res, parent: widget.resourceId));
        }
        setState(() => dropTargetActive = false);
      },
    );
  }

  Widget buildSuperDropRegion(BuildContext context) {
    return DropRegion(
      onDropOver: (event) {
        final localData = event.session.items.first.localData;
        if (localData != null) {
          if ((localData as Iterable).cast<Resource>().map((r) => r.id).contains(widget.resourceId)) {
            return DropOperation.none;
          }
          return DropOperation.copy;
        }
        for (final item in event.session.items) {
          if (item.canProvide(Formats.fileUri)) {
            return DropOperation.copy;
          }
        }

        return DropOperation.none;
      },
      onDropEnter: (event) {
        setState(() => dropTargetActive = true);
      },
      onDropLeave: (event) {
        setState(() => dropTargetActive = false);
      },
      onPerformDrop: (event) async {
        final account = context.read<PhylumAccount>();
        final localData = event.session.items.first.localData;
        if (localData != null) {
          for (final res in (localData as List).cast<Resource>()) {
            account.addAction(ResourceMoveAction(r: res, parent: widget.resourceId));
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
              debugPrint(path.toString());
            }
          }
          if (context.mounted) {
            uploadRecursive(context, widget.resourceId, paths);
          }
        }
        setState(() => dropTargetActive = false);
      },
      formats: Formats.standardFormats,
      child: widget.buildItem(widget.resourceId, dropTargetActive),
    );
  }
}

class ResourceDragSource extends StatelessWidget {
  final int index;
  final Resource resource;
  final bool dropTargetActive;

  const ResourceDragSource({super.key, required this.resource, required this.index, required this.dropTargetActive});

  @override
  Widget build(BuildContext context) {
    return _useSuperNative ? buildSuperDragItem(context) : buildFlutterDraggable(context);
  }

  Widget buildFlutterDraggable(BuildContext context) {
    return Draggable(
      data: '__selected',
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () {
        final controller = context.read<ExplorerViewController>();
        if (!context.read<ExplorerViewState>().isSelected(resource.id)) {
          controller.updateSelection((_) => index, SelectionMode.single, false);
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
              leading: resource.getIcon(),
              title: Text(resource.name),
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

  Widget buildSuperDragItem(BuildContext context) {
    return DragItemWidget(
      allowedOperations: () => [DropOperation.copy, DropOperation.move],
      dragItemProvider: (request) {
        final controller = context.read<ExplorerViewController>();
        if (!context.read<ExplorerViewState>().isSelected(resource.id)) {
          controller.updateSelection((_) => index, SelectionMode.single, false);
        }
        controller.setDragging(true);
        request.session.dragCompleted.addListener(() {
          if (request.session.dragCompleted.value != null) {
            controller.setDragging(false);
          }
        });

        final state = context.read<ExplorerViewState>();
        final item = DragItem(
          localData: state.selected,
        );
        return item;
      },
      canAddItemToExistingSession: false,
      dragBuilder: (ctx, child) {
        final theme = Theme.of(context);
        final state = context.read<ExplorerViewState>();
        final count = state.selectedIds.length;
        return SnapshotSettings(
          constraintsTransform: (constraints) => BoxConstraints(maxWidth: 240, maxHeight: 48),
          child: Card(
            shape: RoundedRectangleBorder(side: BorderSide(color: theme.colorScheme.primary), borderRadius: BorderRadius.circular(4.0)),
            elevation: 16.0,
            margin: const EdgeInsets.only(left: 16.0),
            child: SizedBox(
              width: 240,
              height: 48,
              child: ListTile(
                leading: resource.getIcon(),
                title: Text(resource.name),
                trailing: count == 1 ? null : Badge(label: Text(count.toString(), style: const TextStyle(fontSize: 14))),
              ),
            ),
          ),
        );
      },
      child: DraggableWidget(
        child: ResourceDetailsRow(
          r: resource,
          dropTargetActive: dropTargetActive,
        ),
      ),
    );
  }
}
