import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

import '../../libphylum/explorer/explorer_controller.dart';

class ResourceDetailsRow extends StatelessWidget {
  final Resource resource;
  final bool dropTargetActive;

  ResourceDetailsRow({required this.resource, required this.dropTargetActive}) : super(key: ValueKey(resource.id));

  @override
  Widget build(BuildContext context) {
    final showBorder = context.select<ExplorerState, bool>((state) => state.focusId == resource.id && state.showFocus);
    final highlight = context.select<ExplorerState, bool>((state) => state.isSelected(resource.id));
    final dim = context.select<ExplorerState, bool>((state) => state.isSelected(resource.id) && state.dragging);
    final hasChanges = context.select<PhylumActionQueueState, bool>(
        (state) => state.actions.any((action) => action is ResourceAction && action.resourceId == resource.id));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final border = dropTargetActive
        ? BorderSide(color: colorScheme.secondary, width: 2.0)
        : showBorder
            ? BorderSide(color: colorScheme.primary, width: 2.0)
            : const BorderSide(color: Colors.transparent, width: 2.0);
    String subtitle = "";
    if (resource.modified != null) {
      subtitle = resource.modified!.formatForDisplay();
    }
    if (!resource.dir) {
      if (subtitle.isNotEmpty) {
        subtitle += " \u2022 ";
      }
      subtitle += resource.contentLength.formatForDisplay();
    }
    final color = highlight
        ? dim
            ? colorScheme.primaryContainer.withAlpha(192)
            : colorScheme.primaryContainer
        : dropTargetActive
            ? colorScheme.secondaryContainer
            : Colors.transparent;
    return IconTheme(
      data: IconThemeData(
        size: 24,
        color: colorScheme.onSurfaceVariant,
      ),
      child: Material(
          color: color,
          shape: showBorder
              ? RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(4.0))
              : const Border(),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9.0, horizontal: 16),
                  child: resource.getIcon(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.name,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.fade,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: highlight
                            ? dim
                                ? colorScheme.primary.withAlpha(192)
                                : colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (hasChanges)
                          const Padding(
                            padding: EdgeInsets.only(right: 6.0),
                            child: Icon(Icons.sync, size: 14),
                          ),
                        if (resource.permissions != null)
                          const Padding(
                            padding: EdgeInsets.only(right: 6.0),
                            child: Icon(Icons.people_alt, size: 14),
                          ),
                        if (resource.publinks != null)
                          const Padding(
                            padding: EdgeInsets.only(right: 6.0),
                            child: Icon(Icons.public, size: 14),
                          ),
                        Text(
                          subtitle,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.fade,
                          style: theme.textTheme.bodyMedium!.copyWith(
                            color: highlight
                                ? dim
                                    ? colorScheme.primary.withAlpha(192)
                                    : colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          )),
    );
  }
}
