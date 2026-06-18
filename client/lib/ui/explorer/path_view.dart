import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/util/permissions.dart';
import 'package:provider/provider.dart';

const reverse = false;

class PathView extends StatelessWidget {
  final bool small;

  const PathView({super.key, required this.small});

  @override
  Widget build(BuildContext context) {
    final location = context.watch<ExplorerHistory>().location;
    final account = context.read<PhylumAccount>();
    final folderId = location.folderId(account);
    if (folderId != null) {
      return StreamBuilder(
        stream: account.db.watchParents(folderId),
        initialData: <ParentsResult>[
          ParentsResult(id: folderId, name: 'Folder', userPermission: 0),
        ],
        builder: (context, snapshot) {
          final path = <PathInfo>[];
          DateTime? deleted;
          for (int i = snapshot.data!.length - 1; i >= 0; i--) {
            final entry = snapshot.data![i];
            final permission =
                entry.userPermission | account.user.filesPermissions;
            if (permission != 0) {
              if (entry.id == account.user.home) {
                path.add(
                  PathInfo(
                    title: 'My Files',
                    dropTargetId: entry.id,
                    target: ExplorerLocationHome(),
                  ),
                );
              } else {
                if (path.isEmpty) {
                  path.add(
                    PathInfo(
                      title: 'Shared',
                      dropTargetId: null,
                      target: const ExplorerLocationShared(),
                    ),
                  );
                }
                if (deleted != entry.deleted) {
                  deleted = entry.deleted;
                  path.clear();
                  path.add(
                    PathInfo(
                      title: 'Trash',
                      dropTargetId: null,
                      target: const ExplorerLocationTrash(),
                    ),
                  );
                }
                path.add(
                  PathInfo(
                    title: entry.name,
                    dropTargetId: permission & permissionSetReadWrite == 0
                        ? null
                        : entry.id,
                    target: ExplorerLocationFolder(folderId: entry.id),
                  ),
                );
              }
            }
          }
          if (path.isEmpty) {
            path.add(
              const PathInfo(
                title: 'Folder',
                dropTargetId: null,
                target: null,
                last: true,
              ),
            );
          } else {
            path[path.length - 1] = PathInfo(
              title: path.last.title,
              dropTargetId: null,
              target: null,
              last: true,
            );
          }
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: small
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                  : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Row(
                  children: path
                      .map((info) => PathItem(info, small: small))
                      .toList(growable: false),
                ),
              ),
            ),
          );
        },
      );
    }
    final info = PathInfo(
      title: location.title,
      dropTargetId: null,
      target: null,
      last: true,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [PathItem(info, small: small)]),
      ),
    );
  }
}

class PathInfo {
  final String title;
  final String? dropTargetId;
  final ExplorerLocation? target;
  final bool last;

  const PathInfo({
    required this.title,
    required this.dropTargetId,
    required this.target,
    this.last = false,
  });
}

class PathItem extends StatelessWidget {
  final PathInfo info;
  final bool small;

  const PathItem(this.info, {required this.small, super.key});

  @override
  Widget build(BuildContext context) {
    return info.dropTargetId == null
        ? buildView(context, false)
        : ResourceDragTarget(
            resourceId: info.dropTargetId!,
            buildItem: (context, dropTargetActive) =>
                buildView(context, dropTargetActive),
          );
  }

  Widget buildView(BuildContext context, bool dropTargetActive) {
    if (info.last) return buildCard(context, dropTargetActive);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        buildCard(context, dropTargetActive),
        Icon(Icons.chevron_right, size: small ? 15 : 18),
      ],
    );
  }

  Widget buildCard(BuildContext context, bool dropTargetActive) {
    final theme = Theme.of(context);
    final textStyle = small
        ? theme.textTheme.bodyMedium!
        : theme.textTheme.bodyLarge!;
    final color = info.target == null
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: small
            ? const BorderRadius.all(Radius.circular(3))
            : const BorderRadius.all(Radius.circular(6)),
        side: dropTargetActive
            ? BorderSide(width: small ? 1 : 2, color: theme.colorScheme.primary)
            : BorderSide.none,
      ),
      elevation: info.target == null ? 0 : null,
      margin: small
          ? const EdgeInsets.symmetric(horizontal: 3)
          : const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: info.target == null
            ? null
            : () =>
                  Actions.maybeInvoke(context, NavIntent(target: info.target!)),
        child: Padding(
          padding: small
              ? const EdgeInsets.symmetric(horizontal: 6, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(info.title, style: textStyle.copyWith(color: color)),
        ),
      ),
    );
  }
}
