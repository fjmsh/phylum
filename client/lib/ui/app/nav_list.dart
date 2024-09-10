import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

enum _SyncState {
  done(Icons.cloud_outlined, 'Up-to-date'),
  paused(Icons.sync_disabled, 'Paused'),
  syncing(Icons.cloud_sync, 'Saving'),
  error(Icons.sync_problem, 'Error');

  const _SyncState(this.icon, this.text);

  final IconData icon;
  final String text;
}

class NavList extends StatelessWidget {
  final bool showFab;
  const NavList({super.key, required this.showFab});

  @override
  Widget build(BuildContext context) {
    final qState = context.select<ApiActionQueueState, _SyncState>((state) {
      if (state.submitting) return _SyncState.syncing;
      if (state.error != null) return _SyncState.error;
      if (state.paused) return _SyncState.paused;
      return _SyncState.done;
    });

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
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: Icon(qState.icon),
            title: const Text('Sync'),
            subtitle: Text(qState.text),
            onTap: () {
              final state = context.read<ApiActionQueueState>();
              if (state.error != null) {
                showAlertDialog(context, message: state.error!.description);
              }
            },
          ),
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
