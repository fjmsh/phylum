import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/page.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/util/permissions.dart';
import 'package:provider/provider.dart';

const reverse = false;

class PathView extends StatelessWidget {
  final bool small;

  const PathView({super.key, required this.small});

  @override
  Widget build(BuildContext context) {
    final page = context.select<ExplorerState, ExplorerPage>((state) => state.page);
    final account = context.read<PhylumAccount>();
    if (page is ExplorerPageFolder) {
      final home = account.userHome;
      return StreamBuilder(
          stream: account.db.watchParents(page.folderId),
          initialData: <ParentsResult>[ParentsResult(id: page.folderId, name: 'Folder', userPermission: 0)],
          builder: (context, snapshot) {
            final path = <PathInfo>[];
            for (int i = snapshot.data!.length - 1; i >= 0; i--) {
              final entry = snapshot.data![i];
              final permission = entry.userPermission;
              if (permission != 0) {
                if (entry.id == home) {
                  if (path.isNotEmpty) {
                    path.clear();
                  }
                  path.add(PathInfo(
                      title: 'My Files', dropTargetId: entry.id, targetPage: ExplorerPageHome(context.read())));
                } else {
                  if (path.isEmpty) {
                    path.add(
                        PathInfo(title: 'Shared With Me', dropTargetId: null, targetPage: const ExplorerPageShared()));
                  }
                  path.add(PathInfo(
                    title: entry.name,
                    dropTargetId: permission & permissionSetReadWrite == 0 ? null : entry.id,
                    targetPage: ExplorerPageFolder(folderId: entry.id),
                  ));
                }
              }
            }
            if (path.isEmpty) {
              path.add(const PathInfo(title: 'Folder', dropTargetId: null, targetPage: null, last: true));
            } else {
              path[path.length - 1] = PathInfo(
                title: path.last.title,
                dropTargetId: null,
                targetPage: null,
                last: true,
              );
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: small
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: path.map((info) => PathItem(info, small: small)).toList(growable: false),
                ),
              ),
            );
          });
    }
    final info = PathInfo(title: page.title, dropTargetId: null, targetPage: null, last: true);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [PathItem(info, small: small)],
        ),
      ),
    );
  }
}

class PathInfo {
  final String title;
  final String? dropTargetId;
  final ExplorerPage? targetPage;
  final bool last;

  const PathInfo({
    required this.title,
    required this.dropTargetId,
    required this.targetPage,
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
            buildItem: (context, dropTargetActive) => buildView(context, dropTargetActive),
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
    final textStyle = small ? theme.textTheme.bodyMedium! : theme.textTheme.bodyLarge!;
    final color = info.targetPage == null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant;
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: small ? const BorderRadius.all(Radius.circular(3)) : const BorderRadius.all(Radius.circular(6)),
        side: dropTargetActive ? BorderSide(width: small ? 1 : 2, color: theme.colorScheme.primary) : BorderSide.none,
      ),
      elevation: info.targetPage == null ? 0 : null,
      margin: small ? const EdgeInsets.symmetric(horizontal: 3) : const EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: info.targetPage == null ? null : () => Actions.maybeInvoke(context, NavIntent(target: info.targetPage!)),
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
