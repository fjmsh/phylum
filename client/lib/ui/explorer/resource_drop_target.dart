import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:provider/provider.dart';

class ResourceDropTarget extends StatefulWidget {
  final Resource resource;

  final Widget Function(Resource resource, bool dropTargetActive) buildItem;

  ResourceDropTarget({required this.resource, required this.buildItem}) : super(key: ValueKey(resource.id));

  @override
  State<ResourceDropTarget> createState() => _ResourceDropTargetState();
}

class _ResourceDropTargetState extends State<ResourceDropTarget> {
  bool dropTargetActive = false;

  @override
  Widget build(BuildContext context) {
    return widget.resource.dir
        ? DragTarget(
            builder: (context, candidate, rejected) => widget.buildItem(widget.resource, dropTargetActive),
            onWillAcceptWithDetails: (details) {
              if (context.read<ExplorerViewState>().selectedIds.contains(widget.resource.id)) {
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
                account.addAction(ResourceMoveAction(r: res, parent: widget.resource));
              }
              setState(() => dropTargetActive = false);
            },
          )
        : widget.buildItem(widget.resource, false);
  }
}
