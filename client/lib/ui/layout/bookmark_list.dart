import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/ui/menu/menu_option.dart';
import 'package:phylum/ui/menu/option_groups.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class BookmarkList extends StatelessWidget {
  const BookmarkList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SelectBookmarksResult>>(
      stream: context.read<PhylumAccount>().db.selectBookmarks().watch(),
      initialData: const [],
      builder: (context, snapshot) {
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text('Bookmarks'),
            leading: Icon(Icons.bookmark),
            initiallyExpanded: true,
            children: (snapshot.data ?? const [])
                .map((bookmark) => BookmarkItem(bookmark: bookmark))
                .toList(growable: false),
          ),
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
        supportedDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
        onSecondaryTapUp: (details) =>
            showBookmarkDialog(context, details.globalPosition, bookmark),
        child: ListTile(
          title: Text(bookmark.name),
          leading: Icon(null),
          onTap: () async {
            Scaffold.maybeOf(context)?.closeDrawer();
            if (bookmark.dir) {
              Actions.maybeInvoke(
                  context,
                  NavIntent(
                      target: ExplorerRouteFolder(
                    folderId: bookmark.resourceId,
                  )));
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
    Offset offset,
    SelectBookmarksResult bookmark,
  ) async {
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      offset.dx,
      offset.dy,
    );
    final account = context.read<PhylumAccount>();
    final items = await buildPopupMenuItems(account, [
      [MenuOption.bookmarkEdit, MenuOption.bookmarkRemove]
    ], []);
    if (!context.mounted) return;
    final selection = await showMenu(
      context: context,
      position: position,
      items: items.toList(growable: false),
    );
    if (context.mounted && selection != null) {
      if (selection == MenuOption.bookmarkEdit) {
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
      } else if (selection == MenuOption.bookmarkRemove) {
        account.bookmarkRepository
            .removeBookmark(resourceId: bookmark.resourceId);
      }
    }
  }
}
