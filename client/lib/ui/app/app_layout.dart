import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/search.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:provider/provider.dart';

import 'app_layout_collapsed.dart';

class AppLayout extends StatelessWidget {
  const AppLayout._();

  static Widget create() {
    return MultiProvider(
      providers: [
        StateNotifierProvider<ExplorerController, ExplorerState>(
          create: (context) => ExplorerController(account: context.read(), routerDelegate: context.read()),
          lazy: false,
        ),
        ChangeNotifierProvider(create: (context) => PhylumSearchController(context)),
      ],
      builder: (context, child) {
        final canHandlePop =
            context.watch<PhylumRouterDelegate>().canGoBack || context.watch<ExplorerState>().selectedIds.isNotEmpty;
        return PopScope(
            canPop: !canHandlePop,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              if (!context.read<ExplorerController>().clearSelection()) {
                context.read<PhylumRouterDelegate>().goBack();
              }
            },
            child: child!);
      },
      child: const AppLayout._(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layout = size.width <= 600
        ? const AppLayoutCollapsed()
        : ExpandedAppLayout(
            large: size.width > 1200,
          );
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
                      child: const Center(child: Text('Drop Files to Upload', style: TextStyle(fontSize: 24))),
                    ),
                  )
                ],
              )
            : layout;
        return AppActions(
          child: child,
        );
      },
    );
  }
}

class ExpandedAppLayout extends StatelessWidget {
  final bool large;

  const ExpandedAppLayout({super.key, required this.large});

  @override
  Widget build(BuildContext context) {
    final sidebarWidth = large ? 288.0 : 240.0;

    return Scaffold(
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: sidebarWidth,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 16.0, right: 6.0),
                      child: Image(
                        image: AssetImage('assets/images/logo.png'),
                        height: 36,
                        width: 36,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Text('PHYLUM', style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
              Expanded(
                child: Card(
                  elevation: 0,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(right: 16.0),
                          child: Icon(Icons.search),
                        ),
                        Expanded(
                          child: const SearchField(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (large) SizedBox(width: 360),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: sidebarWidth,
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(left: 16, bottom: 16),
                    child: ExcludeFocusTraversal(child: NavList(drawer: false)),
                  ),
                ),
                Expanded(
                  child: Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: const ExplorerView(small: false),
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
          ),
        ],
      ),
    );
  }
}
