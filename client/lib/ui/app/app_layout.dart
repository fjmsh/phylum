import 'package:flutter/material.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/app/fab_action.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/path_view.dart';

class AppLayout extends StatelessWidget {
  final String folderId;

  const AppLayout({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AppActions(
      folderId: folderId,
      child: width > 800 ? ExpandedAppLayout(folderId: folderId, xLarge: width > 1200) : CollapsedAppLayout(folderId: folderId),
    );
  }
}

class CollapsedAppLayout extends StatelessWidget {
  final String folderId;

  const CollapsedAppLayout({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phylum')),
      drawer: const Drawer(child: NavList(showFab: false)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCreateBottomSheet(context);
        },
        child: Icon(Icons.add),
      ),
      body: ExplorerView.create(folderId, ExplorerLayout.noSidebar),
    );
  }

  void showCreateBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return ListView(
            shrinkWrap: true,
            children: [
              for (final action in FabAction.values)
                ListTile(
                  onTap: () {
                    Navigator.of(context).pop();
                    Actions.maybeInvoke(context, action.intent);
                  },
                  title: Text(action.descripiton),
                  leading: action.icon,
                ),
            ],
          );
        });
  }
}

class ExpandedAppLayout extends StatelessWidget {
  final String folderId;
  final bool xLarge;

  const ExpandedAppLayout({super.key, required this.folderId, required this.xLarge});

  @override
  Widget build(BuildContext context) {
    return AppActions(
      folderId: folderId,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              SizedBox(width: 300, child: Text('Phylum')),
              Expanded(child: PathView.create(folderId)),
            ],
          ),
        ),
        body: Row(
          children: [
            SizedBox(
              width: xLarge ? 300 : 240,
              child: NavList(showFab: true),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                child: ExplorerView.create(folderId, xLarge ? ExplorerLayout.largeSidebar : ExplorerLayout.smallSidebar),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
