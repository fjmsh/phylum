import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/common/expandable_fab.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/path_view.dart';

class AppLayout extends StatelessWidget {
  final String folderId;

  const AppLayout({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    final expandedLayout = MediaQuery.of(context).size.width > 800;

    return AppActions(
      folderId: folderId,
      child: Scaffold(
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
      ),
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
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PathView.create(folderId),
        Expanded(
          child: Card(
            margin: const EdgeInsets.all(12),
            elevation: 0,
            child: ExplorerView.create(folderId),
          ),
        ),
      ],
    );
  }
}
