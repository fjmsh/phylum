import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/nav_history.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

class DestinationPicker extends StatefulWidget {
  final String initialFolderId;

  const DestinationPicker({super.key, required this.initialFolderId});

  @override
  State<DestinationPicker> createState() => _DestinationPickerState();

  static Future<String?> show(BuildContext context, Resource initialFolder) {
    return showDialog(
      context: context,
      builder: (context) => StateNotifierProvider<ExplorerViewController, ExplorerViewState>(
        create: (context) => ExplorerViewController(
          account: context.read<PhylumAccount>(),
          destination: NavDestinationFolder(folderId: initialFolder.id),
        ),
        builder: (_, __) => DestinationPicker(initialFolderId: initialFolder.id),
      ),
    );
  }
}

class _DestinationPickerState extends State<DestinationPicker> {
  final FocusNode node = FocusNode(debugLabel: 'Destination Explorer');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pick Destination'),
        actions: [
          IconButton(
              onPressed: () {
                createDirectory(context, context.read<ExplorerViewState>().folderId);
              },
              icon: Icon(Icons.create_new_folder_outlined))
        ],
      ),
      body: FocusScope(
        child: Actions(
          actions: {
            NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
              final parentId = context.read<ExplorerViewState>().folder?.parent;
              if (parentId != null) {
                context.read<ExplorerViewController>().updateDestination(NavDestinationFolder(folderId: parentId));
              }
              node.requestFocus();
              return null;
            }),
            FocusDownIntent: CallbackAction<FocusDownIntent>(
              onInvoke: (i) async => context.read<ExplorerViewController>().updateSelection((i) => i + 1, SelectionMode.single, false),
            ),
            FocusUpIntent: CallbackAction<FocusUpIntent>(
              onInvoke: (i) async => context.read<ExplorerViewController>().updateSelection((i) => i - 1, SelectionMode.single, false),
            ),
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (i) async {
              final selected = context.read<ExplorerViewState>().selectedSingle;
              if (selected != null && selected.dir) {
                context.read<ExplorerViewController>().updateDestination(NavDestinationFolder(folderId: selected.id));
              }
              return null;
            }),
            DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) => Navigator.of(context).pop()),
          },
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                child: Focus(
                  autofocus: true,
                  focusNode: node,
                  child: ExcludeFocus(child: const DestinationFolderView()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: Navigator.of(context).pop, child: Text('Cancel')),
                    ElevatedButton(
                      onPressed: context.select<ExplorerViewState, bool>((state) => state.folderId == widget.initialFolderId)
                          ? null
                          : () => Navigator.of(context).pop(context.read<ExplorerViewState>().folderId),
                      child: Text('OK'),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class DestinationFolderView extends StatelessWidget {
  const DestinationFolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final items = context.select<ExplorerViewState, List<Resource>>((state) => state.resources);
    return ListView.builder(
      itemBuilder: (BuildContext context, int index) {
        final r = items[index];
        return Builder(builder: (context) {
          final selected = context.select<ExplorerViewState, bool>((state) => state.selectedIds.contains(r.id));
          return ListTile(
            key: ValueKey(r.id),
            visualDensity: VisualDensity.compact,
            selected: selected,
            leading: r.getIcon(),
            title: Text(r.name),
            enabled: r.dir,
            onTap: () => context.read<ExplorerViewController>().updateDestination(NavDestinationFolder(folderId: r.id)),
          );
        });
      },
      itemCount: items.length,
    );
  }
}
