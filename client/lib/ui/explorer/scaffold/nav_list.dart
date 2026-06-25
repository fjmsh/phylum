import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/common/logo_row.dart';
import 'package:phylum/ui/explorer/scaffold/bookmark_list.dart';
import 'package:phylum/ui/explorer/scaffold/create_action.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NavList extends StatelessWidget {
  final bool drawer;
  const NavList({super.key, required this.drawer});

  @override
  Widget build(BuildContext context) {
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
                      context.read<PhylumRouterDelegate>().go(
                        const HomeRoute(),
                      );
                      // Actions.maybeInvoke(
                      //   context,
                      //   NavIntent(target: const ExplorerLocationHome()),
                      // );
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
                      _showAboutDialog(context);
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
    );
  }

  void _showAboutDialog(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showAboutDialog(
      context: context,
      applicationIcon: Image(
        image: AssetImage('assets/images/logo.png'),
        height: 48,
        width: 48,
        fit: BoxFit.contain,
      ),
      applicationVersion:
          '${packageInfo.version} (Server Version ${account.config.version})',
      children: [
        SizedBox(
          width: 360,
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(text: 'Phylum is Free Software offered under the '),
                TextSpan(
                  text: 'GNU AGPL V3.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(
                      Uri.parse(
                        'https://www.gnu.org/licenses/agpl-3.0.en.html',
                      ),
                    ),
                ),
              ],
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: RichText(
            text: TextSpan(
              text: 'View Source on Codeberg',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () =>
                    launchUrl(Uri.parse('https://codeberg.org/shroff/phylum')),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 12.0),
          child: RichText(
            text: TextSpan(
              text: 'Get help on Matrix',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchUrl(
                  Uri.parse('https://matrix.to/#/#phylum_cloud:matrix.org'),
                ),
            ),
          ),
        ),
      ],
    );
  }
}
