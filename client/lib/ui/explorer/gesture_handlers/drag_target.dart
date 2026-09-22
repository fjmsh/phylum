import 'package:flutter/widgets.dart';
import 'package:phylum/libphylum/local_upload_errors.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/util/upload/upload_utils.dart';
import 'package:provider/provider.dart';

class ResourceDragTarget extends StatefulWidget {
  final String resourceId;

  final Function(BuildContext context, bool active) buildItem;

  ResourceDragTarget({required this.resourceId, required this.buildItem})
    : super(key: ValueKey(resourceId));

  @override
  State<ResourceDragTarget> createState() => _ResourceDragTargetState();
}

class _ResourceDragTargetState extends State<ResourceDragTarget> {
  bool dropTargetActive = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget(
      builder: (context, candidate, rejected) =>
          widget.buildItem(context, dropTargetActive),
      onWillAcceptWithDetails: (details) {
        final state = context.read<ExplorerState>();
        // The drag gesture recognizer gets fired before the long press (otherwise it doesn't get fired at all)
        // So the ExplorerState doesn't have a chance to update the selectedIds before this gets called for the first
        // time for touch pointer devices
        // tl;dr needed to fix long-press touch drag start.
        if (details.data == widget.resourceId ||
            state.selectedIds.contains(widget.resourceId) ||
            state.folderId == widget.resourceId) {
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
        for (final r in selected) {
          handleLocalErrors(
            context,
            r.name,
            overwriteFn: (r) => nameConflictDelete,
            (name, conflictResolution, ensurePermission) =>
                account.resourceRepository.move(
                  resource: r,
                  name: name,
                  parent: widget.resourceId,
                  conflictResolution: conflictResolution,
                  ensurePermission: ensurePermission,
                ),
          );
        }
        context.read<ExplorerController>().clearSelection();
        setState(() => dropTargetActive = false);
      },
    );
  }
}
