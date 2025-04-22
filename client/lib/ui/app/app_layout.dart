import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/app/app_actions.dart';
import 'package:phylum/ui/app/fab_action.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/app/search_field.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:phylum/ui/explorer/selection_mode.dart';
import 'package:phylum/ui/menu/bottom_sheet.dart';
import 'package:phylum/ui/menu/option_groups.dart';
import 'package:provider/provider.dart';

class AppLayout extends StatefulWidget {
  const AppLayout._();

  static Widget create() {
    return StateNotifierProvider<ExplorerController, ExplorerState>(
      create: (context) => ExplorerController(account: context.read(), routerDelegate: context.read()),
      lazy: false,
      child: AppLayout._(),
    );
  }

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layout = size.width <= 600
        ? CollapsedAppLayout()
        : ExpandedAppLayout(
            large: size.width > 1200,
            searchFocusNode: _searchFocusNode,
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
        return AppActions(
          searchFocusNode: _searchFocusNode,
          child: child,
        );
      },
    );
  }
}

class CollapsedAppLayout extends StatelessWidget {
  const CollapsedAppLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<ExplorerState, int>((state) => state.selectedIds.length);
    return Scaffold(
      appBar: selected == 0
          ? AppBar(title: const Text('Phylum'))
          : AppBar(
              leading: IconButton(
                tooltip: 'Clear Selection',
                icon: Icon(Icons.close),
                onPressed: () {
                  context.read<ExplorerController>().updateSelection((i) => i, SelectionMode.none, false);
                },
              ),
              title: Text('$selected selected'),
              actions: [
                IconButton(
                    onPressed: () {
                      final selected = context.read<ExplorerState>().selected;
                      var options = resourceOptions;
                      if (selected.every((r) => r.deleted != null)) {
                        options = trashedResourceOptions;
                      }
                      showMenuOptionsBottomSheet(context, options, selected);
                    },
                    icon: Icon(Icons.adaptive.more))
              ],
            ),
      drawer: selected == 0 ? const Drawer(child: NavList(showFab: false)) : null,
      floatingActionButton: selected == 0
          ? FloatingActionButton(
              onPressed: () {
                showCreateBottomSheet(context);
              },
              child: Icon(Icons.add),
            )
          : null,
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
  final FocusNode searchFocusNode;
  final bool large;

  const ExpandedAppLayout({super.key, required this.large, required this.searchFocusNode});

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text('Phylum', style: Theme.of(context).textTheme.headlineLarge),
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
                          child: SearchField(
                            focusNode: searchFocusNode,
                          ),
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
                    child: ExcludeFocusTraversal(child: NavList(showFab: true)),
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
          ),
        ],
      ),
    );
  }
}
