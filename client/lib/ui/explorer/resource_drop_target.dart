import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:provider/provider.dart';

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
}
