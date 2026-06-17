import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/layout/bookmark_list.dart';
import 'package:phylum/ui/layout/button_downloads.dart';
import 'package:phylum/ui/layout/create_action.dart';
import 'package:phylum/ui/settings/settings_page.dart';
import 'package:provider/provider.dart';

class NavList extends StatelessWidget {
  final bool drawer;
  const NavList({super.key, required this.drawer});

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    return SafeArea(
      child: Column(
        children: [
          if (drawer) DrawerHeader(child: const LogoRow()),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!drawer)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: PopupMenuButton(
                        tooltip: 'Create',
                        position: PopupMenuPosition.under,
                        itemBuilder: (context) => [
                          for (final action in getCreateActions(context))
                            if (action == null)
                              const PopupMenuItem(
                                enabled: false,
                                height: 16,
                                child: Divider(),
                              )
                            else
                              PopupMenuItem(
                                child: Text(action.descripiton),
                                onTap: () =>
                                    Actions.maybeInvoke(context, action.intent),
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
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      Scaffold.maybeOf(context)?.closeDrawer();
                      Actions.maybeInvoke(
                        context,
                        NavIntent(target: ExplorerRouteHome()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Recents'),
                    onTap: () {
                      Scaffold.maybeOf(context)?.closeDrawer();
                      context.read<PhylumRouterDelegate>().go(
                        ExplorerRouteRecents(),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outlined),
                    title: const Text('Shared With Me'),
                    onTap: () {
                      Scaffold.maybeOf(context)?.closeDrawer();
                      context.read<PhylumRouterDelegate>().go(
                        ExplorerRouteShared(),
                      );
                    },
                  ),
                  const BookmarkList(),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Trash'),
                    onTap: () {
                      Scaffold.maybeOf(context)?.closeDrawer();
                      context.read<PhylumRouterDelegate>().go(
                        ExplorerRouteTrash(),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () async {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsPage.create(account),
                        ),
                      );
                    },
                  ),
                  if (!kIsWeb) const DownloadButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
