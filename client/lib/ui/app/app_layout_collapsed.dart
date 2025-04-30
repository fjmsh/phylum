import 'package:flutter/material.dart';
import 'package:phylum/ui/app/create_action.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/page.dart';
import 'package:phylum/ui/explorer/selection_mode.dart';
import 'package:phylum/ui/menu/bottom_sheet.dart';
import 'package:phylum/ui/menu/option_groups.dart';
import 'package:provider/provider.dart';

class AppLayoutCollapsed extends StatefulWidget {
  const AppLayoutCollapsed({super.key});

  @override
  State<AppLayoutCollapsed> createState() => _AppLayoutCollapsedState();
}

class _AppLayoutCollapsedState extends State<AppLayoutCollapsed> {
  final TextEditingController _controller = TextEditingController();
  late final PhylumRouterDelegate _routerDelegate;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _routerDelegate = context.read<PhylumRouterDelegate>();
    _routerDelegate.addListener(_onUpdatePage);
    _onUpdatePage();
  }

  @override
  void dispose() {
    _routerDelegate.removeListener(_onUpdatePage);
    super.dispose();
  }

  void _onUpdatePage() {
    final page = _routerDelegate.currentConfiguration;
    if (page is ExplorerPageSearch) {
      _controller.text = page.query;
      _searching = true;
    } else {
      _searching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = context.select<ExplorerState, int>((state) => state.selectedIds.length);
    return Actions(
      actions: {
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) => Focus.maybeOf(context)?.nextFocus()),
      },
      child: Scaffold(
        appBar: selected != 0
            ? AppBar(
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
              )
            : _searching
                ? AppBar(
                    leading: null,
                    title: TextField(
                      controller: _controller,
                    ),
                  )
                : AppBar(
                    title: const Text('Phylum'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () {
                          setState(() {
                            _searching = true;
                          });
                        },
                      )
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
        body: const ExplorerView(small: true),
      ),
    );
  }

  void showCreateBottomSheet(BuildContext context) {
    showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return ListView(
            shrinkWrap: true,
            children: [
              for (final action in getCreateActions(ctx))
                if (action == null)
                  const PopupMenuItem(enabled: false, height: 16, child: Divider())
                else
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
