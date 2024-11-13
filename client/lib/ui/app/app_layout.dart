import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/app/fab_action.dart';
import 'package:phylum/ui/app/app_layout_manager.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/path_view.dart';
import 'package:provider/provider.dart';

class AppLayout extends StatelessWidget {
  const AppLayout({super.key});

  static Widget create(String folderId) {
    return MultiProvider(
      providers: [
        StateNotifierProvider<AppLayoutManager, AppLayoutState>(create: (context) => AppLayoutManager()),
        StateNotifierProvider<ExplorerViewController, ExplorerViewState>(
          create: (context) => ExplorerViewController(account: context.read<PhylumAccount>(), folderId: folderId),
        ),
      ],
      builder: (context, child) {
        final manager = context.read<AppLayoutManager>();
        final platform = Theme.of(context).platform;
        final size = MediaQuery.sizeOf(context);
        Future.microtask(() => manager.update(platform, size));
        return child!;
      },
      child: AppActions(child: AppLayout()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final layout = context.watch<AppLayoutState>();
      return layout.type.isExpanded ? ExpandedAppLayout() : CollapsedAppLayout();
    });
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
  const ExpandedAppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<AppLayoutState>();
    final sidebarWidth = layout.type == LayoutType.expandedLarge ? 300.0 : 240.0;

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
          SizedBox(width: sidebarWidth, child: NavList(showFab: true)),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: const ExplorerView(),
            ),
          ),
        ],
      ),
    );
  }
}
