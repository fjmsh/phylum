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
const small = false;

class PathView extends StatelessWidget {
  const PathView({super.key});

  @override
  Widget build(BuildContext context) {
    final page = context.select<ExplorerState, ExplorerPage>((state) => state.page);
    final account = context.read<PhylumAccount>();
    if (page is ExplorerPageFolder) {
      final user = account.userName;
      final home = account.userHome;
      return StreamBuilder(
          stream: account.db.watchParents(page.folderId),
          initialData: <ParentsResult>[ParentsResult(id: page.folderId, name: 'Folder')],
          builder: (context, snapshot) {
            final path = <PathItem>[];
            for (int i = snapshot.data!.length - 1; i >= 0; i--) {
              final entry = snapshot.data![i];
              final permission = (entry.permissions?.parsePermissionMap() ?? const {})[user] ?? 0;
              if (permission != 0) {
                if (entry.id == home) {
                  if (path.isNotEmpty) {
                    path.clear();
                  }
                  path.add(PathItem(
                      title: 'My Files', dropTargetId: entry.id, targetPage: ExplorerPageHome(context.read())));
                } else {
                  if (path.isEmpty) {
                    path.add(
                        PathItem(title: 'Shared With Me', dropTargetId: null, targetPage: const ExplorerPageShared()));
                  }
                  path.add(PathItem(
                    title: entry.name,
                    dropTargetId: permission & permissionSetReadWrite == 0 ? null : entry.id,
                    targetPage: ExplorerPageFolder(folderId: entry.id),
                  ));
                }
              }
            }
            if (path.isEmpty) {
              path.add(PathItem(title: 'Folder', dropTargetId: null, targetPage: null));
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: small
                    ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                    : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ...path.getRange(0, path.length - 1),
                    PathItem(title: path.last.title, dropTargetId: null, targetPage: null),
                  ],
                ),
              ),
            );
          });
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: small
            ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [PathItem(title: page.title, dropTargetId: null, targetPage: null)],
        ),
      ),
    );
  }
}

class PathItem extends StatelessWidget {
  final String title;
  final String? dropTargetId;
  final ExplorerPage? targetPage;

  const PathItem({
    super.key,
    required this.title,
    required this.dropTargetId,
    required this.targetPage,
  });

  @override
  Widget build(BuildContext context) {
    return dropTargetId == null
        ? buildCard(context, false)
        : ResourceDragTarget(
            resourceId: dropTargetId!,
            buildItem: (context, dropTargetActive) => buildCard(context, dropTargetActive),
          );
  }

  Widget buildCard(BuildContext context, bool dropTargetActive) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        side: dropTargetActive ? BorderSide(width: 2, color: theme.colorScheme.primary) : BorderSide.none,
      ),
      elevation: targetPage == null ? 0 : null,
      margin: EdgeInsets.symmetric(horizontal: 6),
      child: InkWell(
        onTap: targetPage == null ? null : () => Actions.maybeInvoke(context, NavIntent(target: targetPage!)),
        child: Padding(
          padding: small
              ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
              : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(title,
              style: small
                  ? theme.textTheme.bodyMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: targetPage == null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)
                  : theme.textTheme.bodyLarge!.copyWith(
                      color: targetPage == null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant)),
        ),
      ),
    );
  }
}
