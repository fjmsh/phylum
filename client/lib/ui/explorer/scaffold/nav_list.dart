import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/explorer/menu/context_menu_helper.dart';
import 'package:phylum/ui/explorer/menu/menu_option.dart';
import 'package:phylum/ui/explorer/scaffold/create_action.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/ui/explorer/util/about_dialog.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/platform.dart';
import 'package:provider/provider.dart';

class NavList extends StatelessWidget {
  final bool showLogoHeader;
  final bool showCreateButton;

  const NavList({
    super.key,
    required this.showLogoHeader,
    required this.showCreateButton,
  });

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);

    // final selectedButtonColorStyle = ButtonStyle(
    //   backgroundColor: WidgetStateProperty.all(
    //     theme.colorScheme.primaryContainer,
    //   ),
    //   overlayColor: WidgetStateProperty.all(theme.colorScheme.primaryContainer),
    // );

    return TextButtonTheme(
      data: TextButtonThemeData(
        style: TextButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          iconSize: 20,
          enabledMouseCursor: WidgetStateMouseCursor.adaptiveClickable,
          textStyle: TextStyle(fontSize: 14),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            if (showLogoHeader)
              DrawerHeader(child: Center(child: const LogoRow())),
            if (showCreateButton)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: PopupMenuButton(
                  tooltip: 'Create',
                  position: PopupMenuPosition.under,
                  itemBuilder: (context) => <PopupMenuEntry>[
                    for (final action in getCreateActions(context))
                      if (action == null)
                        const PopupMenuDivider()
                      else
                        PopupMenuItem(
                          child: Text(action.descripiton),
                          onTap: () {
                            Scaffold.maybeOf(context)?.closeDrawer();
                            Actions.maybeInvoke(context, action.intent);
                          },
                        ),
                  ],
                  child: FloatingActionButton.extended(
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                    elevation: 0,
                    enableFeedback: false,
                    onPressed: null,
                  ),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.home),
                      label: const Text('Home'),
                      onPressed: () {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<PhylumRouterDelegate>().go(
                          const HomeRoute(),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('Recents'),
                      onPressed: () {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<ExplorerHistoryController>().go(
                          const ExplorerLocationRecents(),
                        );
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.people_outlined),
                      label: const Text('Shared With Me'),
                      onPressed: () {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<ExplorerHistoryController>().go(
                          const ExplorerLocationShared(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Bookmarks',
                        style: TextStyle(
                          fontWeight: .bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    StreamBuilder<List<SelectBookmarksResult>>(
                      stream: context
                          .read<PhylumAccount>()
                          .db
                          .selectBookmarks()
                          .watch(),
                      initialData: const [],
                      builder: (context, snapshot) {
                        return Column(
                          crossAxisAlignment: .stretch,
                          children: (snapshot.data ?? const [])
                              .map(
                                (bookmark) => BookmarkItem(bookmark: bookmark),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Trash'),
                      onPressed: () {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<ExplorerHistoryController>().go(
                          const ExplorerLocationTrash(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: .stretch,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.help_outline),
                  label: const Text('About Phylum'),
                  onPressed: () {
                    Scaffold.maybeOf(context)?.closeDrawer();
                    AboutUtils.show(context);
                  },
                ),
                TextButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                  onPressed: () async {
                    Scaffold.maybeOf(context)?.closeDrawer();
                    context.read<PhylumRouterDelegate>().go(
                      SettingsRoute(selected: null),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
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
      behavior: HitTestBehavior.opaque,
      supportedDevices: {PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
      onTap: () => _handleTap(context),
      onSecondaryTapUp: (details) =>
          _showBookmarkDialog(context, details.globalPosition, bookmark),
      child: TextButton.icon(
        label: Text(bookmark.name, maxLines: 1, overflow: .ellipsis),
        icon: _getIcon(bookmark.dir, bookmark.mimeType ?? ''),
        onPressed: () => _handleTap(context),
        onLongPress: () => _showBookmarkDialog(context, null, bookmark),
      ),
    );
  }

  void _handleTap(BuildContext context) async {
    if (isApple && HardwareKeyboard.instance.isControlPressed) {
      _showBookmarkDialog(context, null, bookmark);
      return;
    }
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
  }

  void _showBookmarkDialog(
    BuildContext context,
    Offset? position,
    SelectBookmarksResult bookmark,
  ) async {
    if (position == null) {
      final options = [MenuOption.bookmarkEdit, MenuOption.bookmarkRemove];
      final option = await showModalBottomSheet(
        context: context,
        builder: (context) {
          final items = options
              .map(
                (option) => ListTile(
                  visualDensity: VisualDensity.adaptivePlatformDensity,
                  leading: Icon(option.icon),
                  title: Text(option.text),
                  onTap: () {
                    Navigator.of(context).pop(option);
                  },
                ),
              )
              .toList(growable: false);
          return ListView(shrinkWrap: true, children: items);
        },
      );
      if (context.mounted && option != null) {
        _onOptionSelected(context, option);
      }
    } else {
      ContextMenuHelper.show(
        context: context,
        position: position,
        groups: [
          [.bookmarkEdit, .bookmarkRemove],
        ],
        onOptionSelected: (option) => _onOptionSelected(context, option),
      );
    }
  }

  void _onOptionSelected(BuildContext context, MenuOption option) async {
    final account = context.read<PhylumAccount>();
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
  }
}

Icon _getIcon(bool dir, String mimeType) {
  if (dir) {
    return const Icon(Icons.folder);
  }

  if (mimeType.startsWith("image")) {
    return const Icon(Icons.image);
  } else if (mimeType.startsWith("video")) {
    return const Icon(Icons.movie);
  } else if (mimeType.startsWith("audio")) {
    return const Icon(Icons.headphones);
  } else if (mimeType.startsWith("text")) {
    return const Icon(Icons.article);
  }
  return const Icon(Icons.insert_drive_file);
}
