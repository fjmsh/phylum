import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/app/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/page.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/explorer/selection_mode.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

class DestinationPicker extends StatefulWidget {
  final String initialFolderId;
  final bool allowInitialFolder;

  const DestinationPicker({super.key, required this.initialFolderId, this.allowInitialFolder = false});

  @override
  State<DestinationPicker> createState() => _DestinationPickerState();

  static Future<String?> show(BuildContext context, String initialFolderId, {bool allowInitialFolder = false}) {
    return showDialog(
      context: context,
      builder: (context) => ChangeNotifierProvider(
        create: (context) => PhylumRouterDelegate(page: ExplorerPageFolder(folderId: initialFolderId)),
        builder: (context, child) {
          final page = context.watch<PhylumRouterDelegate>().currentConfiguration!;
          return StateNotifierProvider<ExplorerController, ExplorerState>(
            key: ValueKey(page),
            create: (context) => ExplorerController(account: context.read(), routerDelegate: context.read()),
            child: child,
          );
        },
        child: DestinationPicker(initialFolderId: initialFolderId, allowInitialFolder: allowInitialFolder),
      ),
    );
  }
}

class _DestinationPickerState extends State<DestinationPicker> {
  final FocusNode node = FocusNode(debugLabel: 'Destination Picker');

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
  Widget build(BuildContext context) =>
      MediaQuery.sizeOf(context).width <= 600 ? buildScaffold(context) : buildDialog(context);

  Widget buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(builder: (context) {
          return BackButton(onPressed: () {
            final parentId = context.read<ExplorerState>().folder?.parent;
            if (parentId != null) {
              context.read<PhylumRouterDelegate>().go(ExplorerPageFolder(folderId: parentId));
              node.requestFocus();
            } else {
              Navigator.of(context).pop();
            }
          });
        }),
        title: Builder(
          builder: (context) {
            final name = context.select<ExplorerState, String?>((state) => state.folder?.name);
            return ListTile(
              title: Text(name ?? ''),
              subtitle: const Text('Pick Destination'),
            );
          },
        ),
        actions: [
          Builder(builder: (context) {
            final folderId = context.select<ExplorerState, String?>((state) => state.folderId);
            return IconButton(
              onPressed: folderId == null ? null : () => createDirectory(context, folderId),
              icon: Icon(Icons.create_new_folder_outlined),
            );
          })
        ],
      ),
      body: _buildContents(context),
    );
  }

  Widget buildDialog(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: _ActionHandler(
        focusNode: node,
        child: AlertDialog(
          titlePadding: EdgeInsets.zero,
          contentPadding: EdgeInsets.zero,
          title: Builder(
            builder: (context) {
              final name = context.select<ExplorerState, String?>((state) => state.folder?.name);
              return ListTile(
                leading: BackButton(onPressed: () {
                  final parentId = context.read<ExplorerState>().folder?.parent;
                  if (parentId != null) {
                    context.read<PhylumRouterDelegate>().go(ExplorerPageFolder(folderId: parentId));
                    node.requestFocus();
                  } else {
                    Navigator.of(context).pop();
                  }
                }),
                title: Text(name ?? ''),
                subtitle: const Text('Pick Destination'),
                trailing: Builder(builder: (context) {
                  final folderId = context.select<ExplorerState, String?>((state) => state.folderId);
                  return IconButton(
                    onPressed: folderId == null ? null : () => createDirectory(context, folderId),
                    icon: Icon(Icons.create_new_folder_outlined),
                  );
                }),
              );
            },
          ),
          content: SizedBox(width: 360, height: 600, child: _buildContents(context)),
        ),
      ),
    );
  }

  Widget _buildContents(BuildContext context) {
    return FocusScope(
      child: _ActionHandler(
        focusNode: node,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(child: _FolderListView(focusNode: node)),
            Divider(thickness: 0, height: 0),
            Padding(
              padding: const EdgeInsets.all(12),
              child: OverflowBar(
                alignment: MainAxisAlignment.end,
                spacing: 8,
                children: [
                  TextButton(onPressed: Navigator.of(context).pop, child: Text('Cancel')),
                  ElevatedButton(
                    onPressed: widget.allowInitialFolder ||
                            context.select<ExplorerState, bool>((state) => state.folderId != widget.initialFolderId)
                        ? () => Navigator.of(context).pop(context.read<ExplorerState>().folderId)
                        : null,
                    child: Text('OK'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _FolderListView extends StatelessWidget {
  final FocusNode focusNode;
  const _FolderListView({required this.focusNode});

  @override
  Widget build(BuildContext context) {
    final items = context.select<ExplorerState, List<Resource>>((state) => state.resources);
    return Focus(
      autofocus: true,
      focusNode: focusNode,
      child: ExcludeFocus(
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            final r = items[index];
            return Builder(builder: (context) {
              final selected = context.select<ExplorerState, bool>((state) => state.selectedIds.contains(r.id));
              return ListTile(
                key: ValueKey(r.id),
                visualDensity: VisualDensity.compact,
                selected: selected,
                leading: r.getIcon(),
                title: Text(r.name),
                enabled: r.dir,
                onTap: () => context.read<PhylumRouterDelegate>().go(ExplorerPageFolder(folderId: r.id)),
              );
            });
          },
          itemCount: items.length,
        ),
      ),
    );
  }
}

class _ActionHandler extends StatelessWidget {
  final Widget child;
  final FocusNode focusNode;
  const _ActionHandler({required this.child, required this.focusNode});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
          final parentId = context.read<ExplorerState>().folder?.parent;
          if (parentId != null) {
            context.read<PhylumRouterDelegate>().go(ExplorerPageFolder(folderId: parentId));
          }
          focusNode.requestFocus();
          return null;
        }),
        FocusDownIntent: CallbackAction<FocusDownIntent>(
          onInvoke: (i) async {
            context.read<ExplorerController>().updateSelection((i) => i + 1, SelectionMode.single, false);
            focusNode.requestFocus();
            return null;
          },
        ),
        FocusUpIntent: CallbackAction<FocusUpIntent>(
          onInvoke: (i) async {
            context.read<ExplorerController>().updateSelection((i) => i - 1, SelectionMode.single, false);
            focusNode.requestFocus();
            return null;
          },
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (i) async {
          final selected = context.read<ExplorerState>().selectedSingle;
          if (selected != null && selected.dir) {
            context.read<PhylumRouterDelegate>().go(ExplorerPageFolder(folderId: selected.id));
          }
          return null;
        }),
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) => Navigator.of(context).pop()),
      },
      child: child,
    );
  }
}
