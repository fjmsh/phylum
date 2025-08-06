import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:drift/drift.dart' show TableOrViewStatements;
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/ui/explorer/resource_sync_state.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

import 'explorer_controller.dart';

const _subtitleIconPadding = 2.0;
const _subtitleIconSize = 16.0;

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

    final sync = context.select<PhylumActionQueueState, ResourceSyncState>((state) {
      return state.actions.fold(ResourceSyncState.none, (acc, action) {
        if (action is ResourceAction && action.resourceId == resource.id) {
          final actionState = ResourceSyncState.fromStatus(action.status);
          if (actionState.index > acc.index) return actionState;
        }
        return acc;
      });
    });

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
                child: Stack(
              fit: StackFit.expand,
              children: [
                StreamBuilder(
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
                    }),
              ],
            )),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sync != ResourceSyncState.none)
                        Padding(
                          padding: const EdgeInsets.only(right: _subtitleIconPadding),
                          child: Icon(sync.icon, size: _subtitleIconSize),
                        ),
                      if (resource.grants != null)
                        Padding(
                          padding: const EdgeInsets.only(right: _subtitleIconPadding),
                          child: Icon(Icons.people_alt, size: _subtitleIconSize),
                        ),
                      StreamBuilder<int>(
                          stream: context.read<PhylumAccount>().db.availableVersions(resource.id).watchSingle(),
                          initialData: 1,
                          builder: (context, snapshot) {
                            if ((snapshot.data ?? 0) > 1) {
                              return Padding(
                                padding: const EdgeInsets.only(right: _subtitleIconPadding),
                                child: Icon(Icons.history, size: _subtitleIconSize),
                              );
                            }
                            return const SizedBox();
                          }),
                      StreamBuilder<int>(
                          stream: account.db.countPublinks(resource.id).watchSingle(),
                          initialData: 0,
                          builder: (context, snapshot) {
                            if ((snapshot.data ?? 0) > 0) {
                              return const Padding(
                                padding: EdgeInsets.only(right: _subtitleIconPadding),
                                child: Icon(Icons.public, size: _subtitleIconSize),
                              );
                            }
                            return const SizedBox();
                          }),
                      StreamBuilder<bool?>(
                          stream: (account.db.bookmarks.select()..where((b) => b.resourceId.equals(resource.id)))
                              .map((b) => !b.deleted)
                              .watchSingleOrNull(),
                          initialData: false,
                          builder: (context, snapshot) {
                            if (snapshot.data == true) {
                              return const Padding(
                                padding: EdgeInsets.only(right: _subtitleIconPadding),
                                child: Icon(Icons.bookmark, size: _subtitleIconSize),
                              );
                            }
                            return const SizedBox();
                          }),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
