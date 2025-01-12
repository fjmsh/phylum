import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

import '../../libphylum/explorer/explorer_controller.dart';

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
    final colorScheme = theme.colorScheme;
    final border = dropTargetActive
        ? BorderSide(color: colorScheme.secondary, width: 2.0)
        : showBorder
            ? BorderSide(color: colorScheme.primary, width: 2.0)
            : const BorderSide(color: Colors.transparent, width: 2.0);
    String subtitle = "";
    if (r.modified != null) {
      subtitle = r.modified!.formatForDisplay();
    }
    if (!r.dir) {
      if (subtitle.isNotEmpty) {
        subtitle += " \u2022 ";
      }
      subtitle += r.contentLength.formatForDisplay();
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
                  child: r.getIcon(),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
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
                    if (subtitle.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (r.permissions != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
                              child: Icon(Icons.people_alt, size: 14),
                            ),
                          if (r.publinks != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6.0),
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
