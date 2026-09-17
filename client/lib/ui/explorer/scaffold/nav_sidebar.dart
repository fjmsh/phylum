import 'package:flutter/material.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/explorer/scaffold/create_action.dart';
import 'package:phylum/ui/explorer/scaffold/sidebar_bookmark_list.dart';
import 'package:phylum/ui/explorer/util/about_dialog.dart';
import 'package:provider/provider.dart';

class NavSidebar extends StatelessWidget {
  const NavSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedButtonColorStyle = ButtonStyle(
      backgroundColor: WidgetStateProperty.all(
        theme.colorScheme.primaryContainer,
      ),
      overlayColor: WidgetStateProperty.all(theme.colorScheme.primaryContainer),
    );
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: .start,
            children: [
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
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: .stretch,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.home),
                        label: const Text('Home'),
                        onPressed: () => context
                            .read<PhylumRouterDelegate>()
                            .go(const HomeRoute()),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.history),
                        label: const Text('Recents'),
                        onPressed: () => context
                            .read<ExplorerHistoryController>()
                            .go(const ExplorerLocationRecents()),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.people_outlined),
                        label: const Text('Shared With Me'),
                        onPressed: () => context
                            .read<ExplorerHistoryController>()
                            .go(const ExplorerLocationShared()),
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
                      const SidebarBookmarkList(),
                      const SizedBox(height: 16),
                      TextButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Trash'),
                        onPressed: () => context
                            .read<ExplorerHistoryController>()
                            .go(const ExplorerLocationTrash()),
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
                    onPressed: () => AboutUtils.show(context),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    onPressed: () async => context
                        .read<PhylumRouterDelegate>()
                        .go(SettingsRoute(selected: null)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
