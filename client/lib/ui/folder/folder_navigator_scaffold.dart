import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/expandable_fab.dart';
import 'package:phylum/ui/folder/nav_list.dart';
import 'package:phylum/ui/folder/folder_contents_view.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

import 'folder_navigator_stack.dart';

class FolderNavigatorView extends StatelessWidget {
  final String root;

  const FolderNavigatorView({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return StateNotifierProvider<FolderNavigatorStack, FolderNavigatorState>(
      create: (context) => FolderNavigatorStack(root),
      builder: (context, child) => const FolderScaffoldResponsive(),
    );
  }
}

class FolderScaffoldResponsive extends StatelessWidget {
  const FolderScaffoldResponsive({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<FolderNavigatorState>();
    final folderId = nav.folderId;
    return MediaQuery.of(context).size.width < 800 ? FolderScaffoldDrawer(folderId: folderId) : FolderScaffoldSidebar(folderId: folderId);
  }
}

class FolderScaffoldDrawer extends StatelessWidget {
  final String folderId;
  FolderScaffoldDrawer({required this.folderId}) : super(key: ValueKey(folderId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phylum')),
      drawer: const Drawer(child: NavList(showFab: false)),
      floatingActionButton: ExpandableFab(
        distance: 112,
        children: [
          ActionButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () async {
              final account = context.read<PhylumAccount>();
              final dirName = await showInputDialog(context, title: 'Create New Folder', labelText: 'Folder Name');
              if (dirName == null || dirName == "") return;
              account.api.sendRequest(ResourceMkdirAction(parent: folderId, resourceName: dirName));
            },
          ),
          ActionButton(
            icon: const Icon(Icons.insert_drive_file),
            onPressed: () async {
              final account = context.read<PhylumAccount>();
              final files = await openFiles();
              for (final file in files) {
                final action = await ResourceUploadAction.fromPath(parent: folderId, resourceName: file.name, path: file.path);
                final error = await account.api.sendRequest(action);
                if (error != null) {
                  debugPrint(error.message);
                }
              }
            },
          ),
        ],
      ),
      body: FolderContentsView(id: folderId),
    );
  }
}

class FolderScaffoldSidebar extends StatelessWidget {
  final String folderId;
  FolderScaffoldSidebar({required this.folderId}) : super(key: ValueKey(folderId));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const NavList(showFab: false),
      body: Row(
        children: [
          SizedBox.fromSize(
            size: const Size.fromWidth(240),
            child: const NavList(showFab: true),
          ),
          Expanded(child: FolderContentsView(id: folderId)),
        ],
      ),
    );
  }
}
