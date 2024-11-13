import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/app/fab_action.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/path_view.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:provider/provider.dart';

class AppLayout {
  const AppLayout();

  static Widget create(String folderId) {
    return MultiProvider(
      providers: [
        StateNotifierProvider<ExplorerViewController, ExplorerViewState>(
          create: (context) => ExplorerViewController(account: context.read<PhylumAccount>(), folderId: folderId),
        ),
      ],
      builder: (context, child) {
        // final platform = Theme.of(context).platform;
        final size = MediaQuery.sizeOf(context);

        final layout = size.width <= 600 ? CollapsedAppLayout() : ExpandedAppLayout(large: size.width > 1200);
        return AppActions(child: layout);
      },
    );
  }
}

class CollapsedAppLayout extends StatelessWidget {
  const CollapsedAppLayout({super.key});

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
      body: const ExplorerView(),
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
  final bool large;
  const ExpandedAppLayout({super.key, required this.large});

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = large ? 288.0 : 216.0;
    final infoWidth = large ? 360.0 : 264.0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            SizedBox(width: sidebarWidth, child: const Text('Phylum')),
            Expanded(child: PathView.create()),
          ],
        ),
      ),
      body: Row(
        children: [
          SizedBox(
            width: sidebarWidth,
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(left: 16, bottom: 16),
              child: NavList(showFab: true),
            ),
          ),
          Expanded(
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: const ExplorerView(),
            ),
          ),
          SizedBox(
            width: infoWidth,
            child: Card(
              elevation: 0,
              margin: const EdgeInsets.only(right: 16, bottom: 16),
              child: ResourceInfoView(),
            ),
          ),
        ],
      ),
    );
  }
}
