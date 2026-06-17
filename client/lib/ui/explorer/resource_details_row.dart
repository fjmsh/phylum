import 'package:drift/drift.dart' as drift;
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

const _rowPaddingV = 2.0;
const _rowPaddingH = 0.0;
const _iconPaddingV = 8.0;
const _iconPaddingH = 16.0;
const _iconSize = 24.0;
const _subtitleIconSize = 14.0;

class ResourceDetailsRow extends StatelessWidget {
  final Resource resource;
  final bool dropTargetActive;

  ResourceDetailsRow({required this.resource, required this.dropTargetActive})
    : super(key: ValueKey(resource.id));

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final showBorder = context.select<ExplorerState, bool>(
      (state) => state.focusId == resource.id && state.showFocus,
    );
    final highlight = context.select<ExplorerState, bool>(
      (state) => state.isSelected(resource.id),
    );
    final dim = context.select<ExplorerState, bool>(
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
    final color = highlight
        ? dim
              ? colorScheme.primaryContainer.withAlpha(192)
              : colorScheme.primaryContainer
        : dropTargetActive
        ? colorScheme.secondaryContainer
        : Colors.transparent;
    return IconTheme(
      data: IconThemeData(size: _iconSize, color: colorScheme.onSurfaceVariant),
      child: Material(
        color: color,
        shape: showBorder
            ? RoundedRectangleBorder(
                side: border,
                borderRadius: BorderRadius.circular(4.0),
              )
            : const Border(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: _rowPaddingV,
            horizontal: _rowPaddingH,
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: _iconPaddingV,
                  horizontal: _iconPaddingH,
                ),
                child: resource.getIcon(account),
              ),
              Expanded(
                child: Column(
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
                        if (sync != ResourceSyncState.none)
                          Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: Icon(sync.icon, size: _subtitleIconSize),
                          ),
                        if (resource.grants != null)
                          const Padding(
                            padding: EdgeInsets.only(right: 6.0),
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
                              return const Padding(
                                padding: EdgeInsets.only(right: 6.0),
                                // TODO: text Scaling and semantic label
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
                                padding: EdgeInsets.only(right: 6.0),
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
                                padding: EdgeInsets.only(right: 6.0),
                                child: Icon(
                                  Icons.bookmark,
                                  size: _subtitleIconSize,
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                        ),
                        StreamBuilder(
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
                              style: theme.textTheme.bodyMedium!.copyWith(
                                color: highlight
                                    ? dim
                                          ? colorScheme.primary.withAlpha(192)
                                          : colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double calculateHeight(BuildContext context) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final titleSize = (TextPainter(
      text: TextSpan(text: 'A', style: theme.textTheme.bodyLarge!),
      maxLines: 1,
      textScaler: scaler,
      textDirection: TextDirection.ltr,
    )..layout()).size.height;
    final subtitleTextSize = (TextPainter(
      text: TextSpan(text: 'A', style: theme.textTheme.bodyMedium!),
      maxLines: 1,
      textScaler: scaler,
      textDirection: TextDirection.ltr,
    )..layout()).size.height;
    // final subtitleTextSize = scaler.scale(theme.textTheme.bodyMedium!.fontSize!);
    final subtitleSize = subtitleTextSize > _subtitleIconSize
        ? subtitleTextSize
        : _subtitleIconSize;
    final contentSize = titleSize + subtitleSize;
    final iconSize = _iconSize + (_iconPaddingV * 2);
    final totalSize =
        (2 * _rowPaddingV) + (iconSize > contentSize ? iconSize : contentSize);
    return totalSize;
  }
}
