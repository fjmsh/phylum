import 'package:flutter/material.dart';
import 'package:phylum/ui/app/create_action.dart';
import 'package:phylum/ui/app/nav_list.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/selection_mode.dart';
import 'package:phylum/ui/menu/bottom_sheet.dart';
import 'package:phylum/ui/menu/option_groups.dart';
import 'package:provider/provider.dart';

class AppLayoutCollapsed extends StatelessWidget {
  const AppLayoutCollapsed({super.key});

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
      body: const ExplorerView(small: true),
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
