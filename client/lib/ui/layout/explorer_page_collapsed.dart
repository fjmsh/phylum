import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/explorer_view.dart';
import 'package:phylum/ui/explorer/selection_mode.dart';
import 'package:phylum/ui/layout/create_action.dart';
import 'package:phylum/ui/layout/nav_list.dart';
import 'package:phylum/ui/layout/search.dart';
import 'package:phylum/ui/layout/sync_status_button.dart';
import 'package:phylum/ui/menu/bottom_sheet.dart';
import 'package:phylum/ui/menu/option_groups.dart';
import 'package:phylum/ui/profile/profile_dialog.dart';
import 'package:phylum/ui/profile/profile_view.dart';
import 'package:provider/provider.dart';

class ExplorerPageCollapsed extends StatelessWidget {
  const ExplorerPageCollapsed({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<ExplorerState, int>((state) => state.selectedIds.length);
    final searching = context.select<PhylumSearchController, bool>((search) => search.active);
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
      body: const ExplorerView(small: true),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool searching, int selected) {
    if (searching) {
      return AppBar(title: SearchField());
    }
    if (selected != 0) {
      return AppBar(
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
                var options = createOptions(context);
                if (selected.every((r) => r.deleted != null)) {
                  options = trashedResourceOptions;
                }
                showMenuOptionsBottomSheet(context, options, selected);
              },
              icon: Icon(Icons.adaptive.more))
        ],
      );
    }

    final account = context.read<PhylumAccount>();

    return AppBar(
      title: const Text('Phylum'),
      actions: [
        const SyncStatusButton(),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: () {
            context.read<PhylumSearchController>().active = true;
          },
        ),
        StreamBuilder(
            stream: account.userNotifier.stream,
            initialData: account.user,
            builder: (context, snapshot) => ProfileView(
                  name: snapshot.data!.name,
                  email: snapshot.data!.email,
                  onTap: () => ProfileDialog.show(context),
                )),
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
