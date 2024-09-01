import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/common/expandable_fab.dart';
import 'package:phylum/ui/folder/folder_heriarchy_view.dart';
import 'package:phylum/ui/folder/nav_list.dart';
import 'package:phylum/ui/folder/folder_contents_view.dart';
import 'package:phylum/ui/folder/upload_utils.dart';
import 'package:provider/provider.dart';

import 'folder_navigator_stack.dart';

class FolderNavigatorView extends StatelessWidget {
  final String root;
  final String name;

  const FolderNavigatorView({super.key, required this.root, required this.name});

  @override
  Widget build(BuildContext context) {
    return StateNotifierProvider<FolderNavigatorStack, FolderNavigatorState>(
      create: (context) => FolderNavigatorStack(root, name),
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
    final expandedLayout = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: expandedLayout ? null : AppBar(title: const Text('Phylum')),
      drawer: expandedLayout ? null : const Drawer(child: NavList()),
      floatingActionButton: expandedLayout
          ? null
          : ExpandableFab(
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
      body: expandedLayout ? buildExpandedBody(folderId) : buildContents(folderId),
    );
  }

  Widget buildExpandedBody(String folderId) {
    return Row(
      children: [
        SizedBox.fromSize(
          size: const Size.fromWidth(240),
          child: NavList(
            fabFolderId: folderId,
          ),
        ),
        Expanded(child: buildContents(folderId)),
      ],
    );
  }

  Widget buildContents(String folderId) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FolderHeriarchyView(),
        Expanded(child: FolderContentsView(id: folderId)),
      ],
    );
  }
}
