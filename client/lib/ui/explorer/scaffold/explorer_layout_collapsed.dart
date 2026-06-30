import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';
import 'package:phylum/ui/explorer/scaffold/create_action.dart';
import 'package:phylum/ui/explorer/scaffold/nav_list.dart';
import 'package:phylum/ui/explorer/scaffold/search/search.dart';
import 'package:phylum/ui/explorer/scaffold/sync/sync_status_button.dart';
import 'package:phylum/ui/explorer/menu/bottom_sheet.dart';
import 'package:provider/provider.dart';

class ExplorerLayoutCollapsed extends StatelessWidget {
  final FocusNode _explorerFocusNode;

  const ExplorerLayoutCollapsed({super.key, required this._explorerFocusNode});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<ExplorerState, int>(
      (state) => state.selectedIds.length,
    );
    final searching = context.select<SearchFieldController, bool>(
      (search) => search.active,
    );
    return Scaffold(
      appBar: _buildAppBar(context, searching, selected),
      drawer: selected == 0 ? const Drawer(child: NavList(drawer: true)) : null,
      floatingActionButton: selected == 0
          ? FloatingActionButton(
              onPressed: () {
                showCreateBottomSheet(context);
              },
              child: Icon(Icons.add),
            )
          : null,
      body: ExplorerView(explorerFocusNode: _explorerFocusNode),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    bool searching,
    int selected,
  ) {
    if (searching) {
      return AppBar(title: SearchField(explorerFocusNode: _explorerFocusNode));
    }
    if (selected != 0) {
      return AppBar(
        leading: IconButton(
          tooltip: 'Clear Selection',
          icon: Icon(Icons.close),
          onPressed: () {
            context.read<ExplorerController>().updateSelection(
              (i) => i,
              SelectionMode.none,
              false,
            );
          },
        ),
        title: Text('$selected selected'),
        actions: [
          IconButton(
            onPressed: () {
              final state = context.read<ExplorerState>();
              final selected = state.selected;
              var options = state.location.selectedResourceOptions;
              showMenuOptionsBottomSheet(context, options, selected);
            },
            icon: Icon(Icons.adaptive.more),
          ),
        ],
      );
    }

    return AppBar(
      title: const Text('Phylum'),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => context.read<SearchFieldController>().active = true,
        ),
        const SyncStatusButton(),
        // ProfileView(onTap: () => ProfileDialog.show(context)),
      ],
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
                const PopupMenuItem(
                  enabled: false,
                  height: 16,
                  child: Divider(),
                )
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
      },
    );
  }
}
