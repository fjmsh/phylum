import 'package:flutter/material.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/explorer/scaffold/bookmark_list.dart';
import 'package:phylum/ui/explorer/util/about_dialog.dart';
import 'package:provider/provider.dart';

class NavDrawer extends StatelessWidget {
  const NavDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(child: const LogoRow()),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.home),
                      title: const Text('Home'),
                      onTap: () {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<PhylumRouterDelegate>().go(
                          const HomeRoute(),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.history),
                      title: const Text('Recents'),
                      onTap: () {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<ExplorerHistoryController>().go(
                          const ExplorerLocationRecents(),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.people_outlined),
                      title: const Text('Shared With Me'),
                      onTap: () {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<ExplorerHistoryController>().go(
                          const ExplorerLocationShared(),
                        );
                      },
                    ),
                    const BookmarkList(),
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Trash'),
                      onTap: () {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<ExplorerHistoryController>().go(
                          const ExplorerLocationTrash(),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('About Phylum'),
                      onTap: () async {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        AboutUtils.show(context);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () async {
                        Scaffold.maybeOf(context)?.closeDrawer();
                        context.read<PhylumRouterDelegate>().go(
                          SettingsRoute(selected: null),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
