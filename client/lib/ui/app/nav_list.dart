import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/app/button_downloads.dart';
import 'package:phylum/ui/app/button_server_status.dart';
import 'package:phylum/ui/app/fab_action.dart';

class NavList extends StatelessWidget {
  final bool showFab;
  const NavList({super.key, required this.showFab});

  @override
  Widget build(BuildContext context) {
    return ExcludeFocusTraversal(
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(left: 16, bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: ListView(
            children: [
              if (showFab)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
        ),
      ),
    );
  }
}
