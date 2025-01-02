import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/ui/menu/option_groups.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

import '../../libphylum/explorer/explorer_controller.dart';
import '../menu/bottom_sheet.dart';

class ResourceDetailsRow extends StatelessWidget {
  final Resource r;
  final bool dropTargetActive;

  ResourceDetailsRow({required this.r, required this.dropTargetActive}) : super(key: ValueKey(r.id));

  @override
  Widget build(BuildContext context) {
    final showBorder = context.select<ExplorerState, bool>((state) => state.focusId == r.id && state.showFocus);
    final highlight = context.select<ExplorerState, bool>((state) => state.isSelected(r.id));
    final dim = context.select<ExplorerState, bool>((state) => state.isSelected(r.id) && state.dragging);
    final theme = Theme.of(context);
    final border = dropTargetActive
        ? BorderSide(color: theme.colorScheme.secondary, width: 2.0)
        : showBorder
            ? BorderSide(color: theme.colorScheme.primary, width: 2.0)
            : const BorderSide(color: Colors.transparent, width: 2.0);
    String subtitle = "";
    if (!r.dir) {
      subtitle = r.contentSize.formatForDisplay();
    }
    if (r.modified != null) {
      if (subtitle.isNotEmpty) {
        subtitle += " \u2022 ";
      }
      subtitle += r.modified!.formatForDisplay();
    }

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
                if (r.publinks != null) Icon(Icons.public, size: 14),
              ],
            ),
          ),
        ],
      ),
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      title: Text(
        r.name,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      subtitle: subtitle.isEmpty
          ? null
          : Text(
              subtitle,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.fade,
            ),
      trailing: IconButton(icon: Icon(Icons.adaptive.more), onPressed: () => showMenuOptionsBottomSheet(context, resourceOptions, [r])),
      shape: RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(4.0)),
      selected: highlight,
      selectedColor: dim ? theme.colorScheme.primary.withOpacity(0.75) : null,
      selectedTileColor: dim ? theme.colorScheme.primaryContainer.withOpacity(0.75) : null,
      tileColor: dropTargetActive ? theme.colorScheme.secondaryContainer : null,
    );
  }
}
