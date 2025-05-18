import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/page.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/layout/button_downloads.dart';
import 'package:phylum/ui/layout/button_server_status.dart';
import 'package:phylum/ui/layout/create_action.dart';
import 'package:phylum/ui/sync/sync_dialog.dart';
import 'package:phylum/util/dialogs.dart';
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
                              const PopupMenuItem(enabled: false, height: 16, child: Divider())
                            else
                              PopupMenuItem(
                                  child: Text(action.descripiton),
                                  onTap: () => Actions.maybeInvoke(context, action.intent)),
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
                    onTap: () {
                      Actions.maybeInvoke(context, NavIntent(target: ExplorerPageHome()));
                      Scaffold.maybeOf(context)?.closeDrawer();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Recents'),
                    onTap: () {
                      context.read<PhylumRouterDelegate>().go(ExplorerPageRecents());
                      Scaffold.maybeOf(context)?.closeDrawer();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outlined),
                    title: const Text('Shared With Me'),
                    onTap: () {
                      context.read<PhylumRouterDelegate>().go(ExplorerPageShared());
                      Scaffold.maybeOf(context)?.closeDrawer();
                    },
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
                                        Actions.maybeInvoke(
                                            context, NavIntent(target: ExplorerPageFolder(folderId: b.resourceId)));
                                        return;
                                      }
                                      final resource = await account.db.getResource(b.resourceId);
                                      if (!context.mounted) return;
                                      if (resource == null) {
                                        final nav = Navigator.of(context);
                                        showProgressDialog(context, title: 'Downloading ${b.name}');
                                        final success = await account.resourceRepository
                                            .requestResource(b.resourceId)
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
                                        Scaffold.maybeOf(context)?.closeDrawer();
                                      }
                                    },
                                  ))
                              .toList(growable: false),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Trash'),
                    onTap: () {
                      context.read<PhylumRouterDelegate>().go(ExplorerPageTrash());
                      Scaffold.maybeOf(context)?.closeDrawer();
                    },
                  ),
                  const Divider(),
                  if (!kIsWeb) const DownloadButton(),
                  ServerStatusButton(
                    onTap: () {
                      SyncDialog.show(context);
                      Scaffold.maybeOf(context)?.closeDrawer();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('About'),
                    onTap: () async {
                      final info = await PackageInfo.fromPlatform();
                      if (!context.mounted) return;
                      showAboutDialog(
                        context: context,
                        applicationVersion: '${info.packageName} - ${info.version} (${info.buildNumber})',
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log Out'),
                    onTap: () {
                      context.read<PhylumAccount>().close(clearData: true);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
