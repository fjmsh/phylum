import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/common/expandable_fab.dart';
import 'package:phylum/ui/folder/nav_list.dart';
import 'package:phylum/ui/folder/folder_contents_view.dart';
import 'package:phylum/ui/folder/upload_utils.dart';
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
      drawer: const Drawer(child: NavList()),
      floatingActionButton: ExpandableFab(
        distance: 112,
        children: [
          ActionButton(
            icon: const Icon(Icons.create_new_folder),
            onPressed: () async {
              createDirectory(context, folderId);
            },
          ),
          ActionButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () async {
              pickAndUploadFiles(context, folderId);
            },
          ),
          ActionButton(
            icon: const Icon(Icons.drive_folder_upload_outlined),
            onPressed: () {
              pickAndUploadDirectory(context, folderId);
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
      body: Row(
        children: [
          SizedBox.fromSize(
            size: const Size.fromWidth(240),
            child: NavList(
              fabFolderId: folderId,
            ),
          ),
          Expanded(child: FolderContentsView(id: folderId)),
        ],
      ),
    );
  }
}
