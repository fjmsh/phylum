import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/common/expandable_fab.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/folder/folder_view.dart';
import 'package:provider/provider.dart';

class CurrentLocation {
  final String folderId;

  CurrentLocation({required this.folderId});
}

class AppScaffold extends StatelessWidget {
  final String folderId;

  const AppScaffold({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Provider<CurrentLocation>(
      key: ValueKey(folderId),
      create: (context) => CurrentLocation(folderId: folderId),
      builder: (context, child) => AppActions(child: child!),
      child: const AppLayout(),
    );
  }
}

class AppLayout extends StatelessWidget {
  const AppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final expandedLayout = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: expandedLayout ? null : AppBar(title: const Text('Phylum')),
      drawer: expandedLayout
          ? null
          : const Drawer(
              child: NavList(
              showFab: false,
            )),
      floatingActionButton: expandedLayout
          ? null
          : ExpandableFab(
              distance: 112,
              children: [
                ActionButton(
                  icon: const Icon(Icons.create_new_folder),
                  onPressed: () async {
                    Actions.maybeInvoke(context, const NewFolderIntent());
                  },
                ),
                ActionButton(
                  icon: const Icon(Icons.upload_file),
                  onPressed: () async {
                    Actions.maybeInvoke(context, const UploadFilesIntent());
                  },
                ),
                ActionButton(
                  icon: const Icon(Icons.drive_folder_upload_outlined),
                  onPressed: () {
                    Actions.maybeInvoke(context, const UploadFolderIntent());
                  },
                ),
              ],
            ),
      body: expandedLayout ? buildExpandedBody() : buildContents(),
    );
  }

  Widget buildExpandedBody() {
    return Row(
      children: [
        const SizedBox(
          width: 240,
          child: NavList(showFab: true),
        ),
        Expanded(child: buildContents()),
      ],
    );
  }

  Widget buildContents() {
    return const Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FolderHeriarchyView(),
        Expanded(child: FolderView()),
      ],
    );
  }
}
