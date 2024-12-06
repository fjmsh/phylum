import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/explorer/explorer_navigator.dart';
import 'package:phylum/libphylum/explorer/page.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/button_downloads.dart';
import 'package:phylum/ui/app/button_server_status.dart';
import 'package:phylum/ui/app/fab_action.dart';
import 'package:provider/provider.dart';

class NavList extends StatelessWidget {
  final bool showFab;
  const NavList({super.key, required this.showFab});

  @override
  Widget build(BuildContext context) {
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
                      PopupMenuItem(child: Text(action.descripiton), onTap: () => Actions.maybeInvoke(context, action.intent)),
                ],
                child: FloatingActionButton.extended(
                    icon: const Icon(Icons.add), label: const Text('New'), elevation: 0, enableFeedback: false, onPressed: null),
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
          StreamBuilder<List<ListBookmarksResult>>(
            stream: context.read<PhylumAccount>().myListsRepository.listBookmarks().watch(),
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
                            onTap: () => Actions.maybeInvoke(context, NavToFolderIntent(folderId: b.resourceId)),
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
