import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:provider/provider.dart';

import 'explorer_view_controller.dart';
import 'resource_options_dialog.dart';

class ResourceDetailsRow extends StatelessWidget {
  final Resource r;
  final bool dropTargetActive;

  ResourceDetailsRow({required this.r, required this.dropTargetActive}) : super(key: ValueKey(r.id));

  @override
  Widget build(BuildContext context) {
    final showBorder = context.select<ExplorerViewState, bool>((state) => state.focusId == r.id && state.showFocus);
    final highlight = context.select<ExplorerViewState, bool>((state) => state.isSelected(r.id));
    final dim = context.select<ExplorerViewState, bool>((state) => state.isSelected(r.id) && state.dragging);
    final theme = Theme.of(context);
    final border = dropTargetActive
        ? BorderSide(color: theme.colorScheme.secondary, width: 2.0)
        : showBorder
            ? BorderSide(color: theme.colorScheme.primary, width: 2.0)
            : const BorderSide(color: Colors.transparent, width: 2.0);

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          r.getIcon(),
          SizedBox(
            width: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (r.permissions != null) Icon(Icons.people_alt, size: 14),
                if (r.publinks > 0) Icon(Icons.public, size: 14),
              ],
            ),
          ),
        ],
      ),
      title: Text(r.name),
      trailing: ResourceOptionsButton(r: r),
      shape: RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(4.0)),
      selected: highlight,
      selectedColor: dim ? theme.colorScheme.primary.withOpacity(0.75) : null,
      selectedTileColor: dim ? theme.colorScheme.primaryContainer.withOpacity(0.75) : null,
      tileColor: dropTargetActive ? theme.colorScheme.secondaryContainer : null,
    );
  }
}
