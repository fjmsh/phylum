import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/common/expandable_fab.dart';
import 'package:phylum/ui/folder/folder_contents_view.dart';
import 'package:provider/provider.dart';

import 'folder_navigator_stack.dart';

class FolderNavigatorView extends StatelessWidget {
  final String root;

  const FolderNavigatorView({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return StateNotifierProvider<FolderNavigatorStack, FolderNavigatorState>(
      create: (context) => FolderNavigatorStack(root),
      builder: (context, child) => const FolderScaffold(),
    );
  }
}

class FolderScaffold extends StatelessWidget {
  const FolderScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<FolderNavigatorState>();
    final folderId = nav.folderId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phylum'),
        leading: nav.isRoot ? null : BackButton(onPressed: context.read<FolderNavigatorStack>().pop),
      ),
      floatingActionButton: ExpandableFab(
        distance: 112,
        children: [
          ActionButton(
            icon: const Icon(Icons.folder),
            onPressed: () {},
          ),
          ActionButton(
            icon: const Icon(Icons.insert_drive_file),
            onPressed: () {},
          ),
        ],
      ),
      body: FolderContentsView(key: ValueKey(folderId), id: folderId),
    );
  }
}
