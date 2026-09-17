import 'package:cached_network_image/cached_network_image.dart';
import 'package:drift/drift.dart' show TableOrViewStatements;
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/imgres.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/ui/explorer/util/icon_extensions.dart';
import 'package:phylum/ui/explorer/resource_sync_state.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

import '../../explorer_controller.dart';

const _subtitleIconPadding = 2.0;
const _subtitleIconSize = 16.0;

class FolderGridItem extends StatelessWidget {
  final Resource resource;
  final bool dropTargetActive;

  FolderGridItem({required this.resource, required this.dropTargetActive})
    : super(key: ValueKey(resource.id));

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final showBorder = context.select<ExplorerState, bool>(
      (state) => state.focusId == resource.id && state.showFocus,
    );
    final selected = context.select<ExplorerState, bool>(
      (state) => state.isSelected(resource.id),
    );
    final dragging = context.select<ExplorerState, bool>(
      (state) => state.isSelected(resource.id) && state.dragging,
    );

    final sync = context.select<PhylumActionQueueState, ResourceSyncState>((
      state,
    ) {
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

    final color = selected
        ? colorScheme.primaryContainer.withAlpha(dragging ? 192 : 255)
        : dropTargetActive
        ? colorScheme.secondaryContainer
        : colorScheme.surfaceContainerHighest;

    final textColor = selected
        ? colorScheme.primary.withAlpha(dragging ? 192 : 255)
        : null;

    return IconTheme(
      data: IconThemeData(color: colorScheme.onSurfaceVariant),
      child: Card(
        color: color,
        borderOnForeground: true,
        clipBehavior: Clip.antiAlias,
        shape: dropTargetActive || showBorder
            ? RoundedRectangleBorder(
                side: border,
                borderRadius: const BorderRadius.all(Radius.circular(12.0)),
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  StreamBuilder(
                    stream: account.db
                        .latestVersion(resource.id)
                        .watchSingleOrNull(),
                    builder: (context, snapshot) {
                      String imageUrl = '';
                      if (snapshot.data != null &&
                          (snapshot.data!.imgres & imgResThumbnail) != 0) {
                        imageUrl =
                            (account.apiClient.createUriBuilder(
                                    '/api/v1/fs/img/${resource.id}:',
                                  )
                                  ..queryParameters['version'] =
                                      snapshot.data!.id
                                  ..queryParameters['res'] = imgResThumbnail
                                      .toString())
                                .build()
                                .toString();
                      }
                      return Container(
                        margin: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainer,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          alignment: const Alignment(0.0, -0.75),
                          fit: .cover,
                          httpHeaders: account.apiClient.requestHeaders,
                          placeholder: (context, url) => FittedBox(
                            fit: .contain,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: resource.getIcon(account),
                            ),
                          ),
                          imageRenderMethodForWeb: .HttpGet,
                          errorWidget: (context, url, err) => FittedBox(
                            fit: .contain,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: resource.getIcon(account),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(color: color),
              padding: const EdgeInsets.symmetric(
                vertical: 6.0,
                horizontal: 12.0,
              ),
              child: Column(
                crossAxisAlignment: .stretch,
                children: [
                  Text(
                    resource.name,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor ?? colorScheme.onSurface,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: .center,
                    mainAxisSize: .min,
                    children: [
                      if (sync != ResourceSyncState.none)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: _subtitleIconPadding,
                          ),
                          child: Icon(sync.icon, size: _subtitleIconSize),
                        ),
                      if (resource.grants != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            right: _subtitleIconPadding,
                          ),
                          child: Icon(
                            Icons.people_alt,
                            size: _subtitleIconSize,
                          ),
                        ),
                      StreamBuilder<int>(
                        stream: context
                            .read<PhylumAccount>()
                            .db
                            .availableVersions(resource.id)
                            .watchSingle(),
                        initialData: 1,
                        builder: (context, snapshot) {
                          if ((snapshot.data ?? 0) > 1) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                right: _subtitleIconPadding,
                              ),
                              child: Icon(
                                Icons.history,
                                size: _subtitleIconSize,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      StreamBuilder<int>(
                        stream: account.db
                            .countPublinks(resource.id)
                            .watchSingle(),
                        initialData: 0,
                        builder: (context, snapshot) {
                          if ((snapshot.data ?? 0) > 0) {
                            return const Padding(
                              padding: EdgeInsets.only(
                                right: _subtitleIconPadding,
                              ),
                              child: Icon(
                                Icons.public,
                                size: _subtitleIconSize,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      StreamBuilder<bool?>(
                        stream:
                            (account.db.bookmarks.select()..where(
                                  (b) => b.resourceId.equals(resource.id),
                                ))
                                .map((b) => !b.deleted)
                                .watchSingleOrNull(),
                        initialData: false,
                        builder: (context, snapshot) {
                          if (snapshot.data == true) {
                            return const Padding(
                              padding: EdgeInsets.only(
                                right: _subtitleIconPadding,
                              ),
                              child: Icon(
                                Icons.bookmark,
                                size: _subtitleIconSize,
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                      Expanded(
                        child: StreamBuilder(
                          stream: account.db
                              .latestVersion(resource.id)
                              .watchSingleOrNull(),
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
                              style: TextStyle(
                                fontSize: 13.5,
                                color:
                                    textColor ?? colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
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
