import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/explorer/explorer_navigator.dart';
import 'package:phylum/libphylum/explorer/page.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/button_downloads.dart';
import 'package:phylum/ui/app/button_server_status.dart';
import 'package:phylum/ui/app/fab_action.dart';
import 'package:phylum/ui/preview/resource_preview.dart';
import 'package:provider/provider.dart';

class NavList extends StatelessWidget {
  final bool showFab;
  const NavList({super.key, required this.showFab});

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return ExcludeFocusTraversal(
      child: ListView(
        children: [
          if (showFab)
            Padding(
              padding: const EdgeInsets.all(16),
              child: PopupMenuButton(
                tooltip: 'Create',
                position: PopupMenuPosition.under,
                itemBuilder: (context) => [
                  for (final action in popupMenuActions)
                    if (action == null)
                      const PopupMenuItem(enabled: false, height: 16, child: Divider())
                    else
                      PopupMenuItem(
                          child: Text(action.descripiton), onTap: () => Actions.maybeInvoke(context, action.intent)),
                ],
                child: FloatingActionButton.extended(
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
                    elevation: 0,
                    enableFeedback: false,
                    onPressed: null),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Actions.maybeInvoke(context, const NavHomeIntent()),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Recents'),
            onTap: () => context.read<ExplorerNavigator>().go(ExplorerPageRecents()),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Trash'),
            onTap: () => context.read<ExplorerNavigator>().go(ExplorerPageTrash()),
          ),
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Shared With Me'),
            onTap: () => context.read<ExplorerNavigator>().go(ExplorerPageShared()),
          ),
          StreamBuilder<List<SelectBookmarksResult>>(
            stream: account.db.selectBookmarks().watch(),
            initialData: const [],
            builder: (context, snapshot) {
              return Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: Text('Bookmarks'),
                  leading: Icon(Icons.bookmark),
                  initiallyExpanded: true,
                  children: (snapshot.data ?? const [])
                      .map((b) => ListTile(
                            title: Text(b.name),
                            leading: Icon(null),
                            onTap: () async {
                              if (b.dir) {
                                Actions.maybeInvoke(context, NavToFolderIntent(folderId: b.resourceId));
                                return;
                              }
                              final resource = await account.db.getResource(b.resourceId);
                              if (resource != null && context.mounted) {
                                ResourcePreview.showPreview(context, [resource], 0);
                                return;
                              }
                              // TODO: load resource from server
                            },
                          ))
                      .toList(growable: false),
                ),
              );
            },
          ),
          const Divider(),
          const DownloadButton(),
          const ServerStatusButton(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
