import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/explorer/menu/context_menu_helper.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class SidebarBookmarkList extends StatelessWidget {
  const SidebarBookmarkList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SelectBookmarksResult>>(
      stream: context.read<PhylumAccount>().db.selectBookmarks().watch(),
      initialData: const [],
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: .stretch,
          children: (snapshot.data ?? const [])
              .map((bookmark) => BookmarkItem(bookmark: bookmark))
              .toList(growable: false),
        );
      },
    );
  }
}

class BookmarkItem extends StatelessWidget {
  final SelectBookmarksResult bookmark;
  BookmarkItem({required this.bookmark})
    : super(key: ValueKey(bookmark.resourceId));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      supportedDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      },
      onLongPressEnd: (details) =>
          showBookmarkDialog(context, details.globalPosition, bookmark),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        supportedDevices: {PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
        onSecondaryTapUp: (details) =>
            showBookmarkDialog(context, details.globalPosition, bookmark),
        child: TextButton.icon(
          label: Text(bookmark.name, maxLines: 1, overflow: .ellipsis),
          icon: Icon(null),
          onPressed: () async {
            Scaffold.maybeOf(context)?.closeDrawer();
            if (bookmark.dir) {
              Actions.maybeInvoke(
                context,
                NavIntent(
                  target: ExplorerLocationFolder(folderId: bookmark.resourceId),
                ),
              );
              return;
            }
            final account = context.read<PhylumAccount>();
            final resource = await account.db.getResource(bookmark.resourceId);
            if (!context.mounted) return;
            if (resource == null) {
              final nav = Navigator.of(context);
              showProgressDialog(
                context,
                title: 'Getting Details',
                message: bookmark.name,
              );
              final success = await account.resourceRepository
                  .requestResource(bookmark.resourceId)
                  .then((result) => result is ApiSuccessResponse);
              nav.pop();
              if (!success) {
                if (context.mounted) {
                  showAlertDialog(context, title: 'Unable to get file info');
                }
                return;
              }
            }
            if (resource != null && context.mounted) {
              Actions.maybeInvoke(context, OpenResourceIntent(resource));
            }
          },
        ),
      ),
    );
  }

  void showBookmarkDialog(
    BuildContext context,
    Offset position,
    SelectBookmarksResult bookmark,
  ) async {
    final account = context.read<PhylumAccount>();

    ContextMenuHelper.show(
      context: context,
      position: position,
      groups: [
        [.bookmarkEdit, .bookmarkRemove],
      ],
      onOptionSelected: (option) async {
        if (option == .bookmarkEdit) {
          if (!context.mounted) return;
          final name = await showInputDialog(
            context,
            autocorrect: false,
            title: 'Edit Bookmark',
            labelText: 'Name',
            preset: bookmark.name,
          );
          if (name == null || name.trim().isEmpty || name == bookmark.name) {
            return;
          }
          account.bookmarkRepository.addBookmarkDirect(
            resourceId: bookmark.resourceId,
            dir: bookmark.dir,
            name: name,
          );
        } else if (option == .bookmarkRemove) {
          account.bookmarkRepository.removeBookmark(
            resourceId: bookmark.resourceId,
          );
        }
      },
    );
  }
}
