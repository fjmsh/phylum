import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'explorer_controller.dart';

class FolderGridItem extends StatelessWidget {
  final Resource resource;
  final bool dropTargetActive;

  FolderGridItem({required this.resource, required this.dropTargetActive}) : super(key: ValueKey(resource.id));

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final showBorder = context.select<ExplorerState, bool>((state) => state.focusId == resource.id && state.showFocus);
    final highlight = context.select<ExplorerState, bool>((state) => state.isSelected(resource.id));
    final dim = context.select<ExplorerState, bool>((state) => state.isSelected(resource.id) && state.dragging);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final border = dropTargetActive
        ? BorderSide(color: colorScheme.secondary, width: 2.0)
        : showBorder
            ? BorderSide(color: colorScheme.primary, width: 2.0)
            : const BorderSide(color: Colors.transparent, width: 2.0);

    final color = highlight
        ? dim
            ? colorScheme.primaryContainer.withAlpha(192)
            : colorScheme.primaryContainer
        : dropTargetActive
            ? colorScheme.secondaryContainer
            : null;

    return IconTheme(
      data: IconThemeData(
        color: colorScheme.onSurfaceVariant,
      ),
      child: Card(
        color: color,
        borderOnForeground: true,
        clipBehavior: Clip.antiAlias,
        shape: dropTargetActive || showBorder
            ? RoundedRectangleBorder(side: border, borderRadius: BorderRadius.circular(12.0))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: StreamBuilder(
                    stream: account.db.latestVersion(resource.id).watchSingleOrNull(),
                    builder: (context, snapshot) {
                      String imageUrl = '';
                      if (snapshot.data != null && snapshot.data?.preview == true) {
                        imageUrl = (account.apiClient.createUriBuilder('/api/v1/fs/preview/${resource.id}:')
                              ..queryParameters['version'] = snapshot.data!.id)
                            .build()
                            .toString();
                      }
                      return CachedNetworkImage(
                        imageUrl: imageUrl,
                        alignment: Alignment.topCenter,
                        fit: BoxFit.cover,
                        httpHeaders: account.apiClient.requestHeaders,
                        placeholder: (context, url) => FittedBox(
                            fit: BoxFit.contain,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: resource.getIcon(account),
                            )),
                        imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                        errorWidget: (context, url, err) => FittedBox(
                            fit: BoxFit.contain,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: resource.getIcon(account),
                            )),
                      );
                    })),
            Container(
              decoration: BoxDecoration(color: color ?? Theme.of(context).colorScheme.surfaceContainerLow),
              padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  StreamBuilder(
                      stream: account.db.latestVersion(resource.id).watchSingleOrNull(),
                      builder: (context, snapshot) {
                        String subtitle = "";
                        if (resource.modified != null) {
                          subtitle = resource.modified!.formatShort();
                        }
                        final data = snapshot.data;
                        if (data != null) {
                          if (subtitle.isNotEmpty) {
                            subtitle += " \u2022 ";
                          }
                          subtitle += data.size.formatForDisplay();
                        }
                        return Text(
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
                        );
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
