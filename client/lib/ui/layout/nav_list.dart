import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/dialogs/new_user_details_dialog.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/layout/button_downloads.dart';
import 'package:phylum/ui/layout/button_sync_status.dart';
import 'package:phylum/ui/layout/create_action.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/user_display_name.dart';
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
                      Scaffold.maybeOf(context)?.closeDrawer();
                      Actions.maybeInvoke(context, NavIntent(target: ExplorerRouteHome()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Recents'),
                    onTap: () {
                      Scaffold.maybeOf(context)?.closeDrawer();
                      context.read<PhylumRouterDelegate>().go(ExplorerRouteRecents());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people_outlined),
                    title: const Text('Shared With Me'),
                    onTap: () {
                      Scaffold.maybeOf(context)?.closeDrawer();
                      context.read<PhylumRouterDelegate>().go(ExplorerRouteShared());
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
                                      Scaffold.maybeOf(context)?.closeDrawer();
                                      if (b.dir) {
                                        Actions.maybeInvoke(
                                            context, NavIntent(target: ExplorerRouteFolder(folderId: b.resourceId)));
                                        return;
                                      }
                                      final resource = await account.db.getResource(b.resourceId);
                                      if (!context.mounted) return;
                                      if (resource == null) {
                                        final nav = Navigator.of(context);
                                        showProgressDialog(context, title: 'Getting Details', message: b.name);
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
                      Scaffold.maybeOf(context)?.closeDrawer();
                      context.read<PhylumRouterDelegate>().go(ExplorerRouteTrash());
                    },
                  ),
                  const Divider(),
                  StateNotifierBuilder(
                      stateNotifier: account.userNotifier,
                      builder: (context, state, child) {
                        return state.hasPermission(permissionUsersInvite)
                            ? Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.person_add),
                                    title: const Text('Invite'),
                                    onTap: () async {
                                      final messenger = ScaffoldMessenger.maybeOf(context);
                                      final account = context.read<PhylumAccount>();
                                      Scaffold.maybeOf(context)?.closeDrawer();
                                      final result = await NewUserDetailsDialog.show(context);
                                      if (result == null) return;
                                      final (email, name) = result;
                                      final user = await account.userRepository.invite(email, name);
                                      messenger?.showSnackBar(SnackBar(
                                        content: Text('Invited ${user.displayName}'),
                                        duration: Duration(seconds: 2),
                                      ));
                                    },
                                  ),
                                  Divider()
                                ],
                              )
                            : SizedBox();
                      }),
                  if (!kIsWeb) const DownloadButton(),
                  const SyncStatusButton(),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('About'),
                    onTap: () async {
                      Scaffold.maybeOf(context)?.closeDrawer();
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
                      Scaffold.maybeOf(context)?.closeDrawer();
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
