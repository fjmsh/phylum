import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/app/fab_action.dart';
import 'package:phylum/ui/app/nav_history.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/path_view.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:provider/provider.dart';

class AppLayout {
  const AppLayout();

  static Widget create(NavDestination destination) {
    return MultiProvider(
      providers: [
        StateNotifierProvider<ExplorerViewController, ExplorerViewState>(
          create: (context) => ExplorerViewController(
            navHistoryManager: context.read<NavHistoryManager>(),
            account: context.read<PhylumAccount>(),
          ),
        ),
      ],
      builder: (context, child) {
        final size = MediaQuery.sizeOf(context);
        final navHistoryManager = context.read<NavHistoryManager>();
        Future.microtask(() => navHistoryManager.handleDestinationChange(destination));
        final layout = size.width <= 600 ? CollapsedAppLayout() : ExpandedAppLayout(large: size.width > 1200);
        return ExternalDropRegion(
          buildItem: (context, dropTargetActive) {
            final child = (dropTargetActive)
                ? Stack(
                    children: [
                      layout,
                      ConstrainedBox(
                        constraints: BoxConstraints.expand(),
                        child: Material(
                          color: Colors.white70,
                          child: const Center(
                              child: Text(
                            'Drop Files to Upload',
                            style: TextStyle(fontSize: 24),
                          )),
                        ),
                      )
                    ],
                  )
                : layout;
            return AppActions(child: child);
          },
        );
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
    final sidebarWidth = large ? 288.0 : 240.0;

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
          if (large)
            SizedBox(
              width: 360,
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.only(right: 16, bottom: 16),
                child: ReactiveResourceInfoView(),
              ),
            ),
        ],
      ),
    );
  }
}
