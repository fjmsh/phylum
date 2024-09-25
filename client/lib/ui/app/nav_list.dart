import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/app/button_downloads.dart';
import 'package:phylum/ui/app/button_server_status.dart';

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
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('New'),
                onPressed: () {
                  showMenu(
                    context: context,
                    position: const RelativeRect.fromLTRB(0, 0, 0, 0),
                    items: [
                      PopupMenuItem(child: const Text('Create Folder'), onTap: () => Actions.maybeInvoke(context, const NewFolderIntent())),
                      const PopupMenuItem(enabled: false, height: 16, child: Divider()),
                      PopupMenuItem(child: const Text('Upload File(s)'), onTap: () => Actions.maybeInvoke(context, const UploadFilesIntent())),
                      PopupMenuItem(child: const Text('Upload Folder'), onTap: () => Actions.maybeInvoke(context, const UploadFolderIntent())),
                    ],
                  );
                },
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
    );
  }
}
