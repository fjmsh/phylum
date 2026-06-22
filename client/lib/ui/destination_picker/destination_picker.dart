import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/util/icon_extensions.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

part 'action_handler.dart';

class DestinationPicker extends StatefulWidget {
  final String initialFolderId;
  final bool allowInitialFolder;

  const DestinationPicker({
    super.key,
    required this.initialFolderId,
    this.allowInitialFolder = false,
  });

  @override
  State<DestinationPicker> createState() => _DestinationPickerState();

  static Future<String?> show(
    BuildContext context, {
    String? initialFolderId,
    bool allowInitialFolder = false,
  }) {
    final account = context.read<PhylumAccount>();
    initialFolderId ??= account.user.home;
    return showDialog(
      context: context,
      builder: (context) => MultiProvider(
        providers: [
          StateNotifierProvider<PhylumAccount, AccountState>.value(
            value: account,
          ),
          StateNotifierProvider<ExplorerHistoryController, ExplorerHistory>(
            create: (context) => ExplorerHistoryController(
              initialLocation: ExplorerLocationFolder(
                folderId: initialFolderId!,
              ),
            ),
          ),
          StateNotifierProvider<ExplorerController, ExplorerState>(
            create: (context) => ExplorerController(
              account: context.read(),
              historyController: context.read(),
            ),
          ),
        ],
        child: DestinationPicker(
          initialFolderId: initialFolderId!,
          allowInitialFolder: allowInitialFolder,
        ),
      ),
    );
  }
}

class _DestinationPickerState extends State<DestinationPicker> {
  final FocusNode node = FocusNode(debugLabel: 'Destination Picker');

  @override
  void dispose() {
    node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width <= 600
      ? buildScaffold(context)
      : buildDialog(context);

  Widget buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return BackButton(
              onPressed: () {
                final parentId = context.read<ExplorerState>().folder?.parent;
                if (parentId != null) {
                  context.read<ExplorerHistoryController>().go(
                    ExplorerLocationFolder(folderId: parentId),
                  );
                  node.requestFocus();
                } else {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        ),
        title: Builder(
          builder: (context) {
            final name = context.select<ExplorerState, String?>(
              (state) => state.folder?.name,
            );
            return ListTile(
              title: Text(name ?? ''),
              subtitle: const Text('Pick Destination'),
            );
          },
        ),
        actions: [
          Builder(
            builder: (context) {
              final folderId = context.select<ExplorerState, String?>(
                (state) => state.folderId,
              );
              return IconButton(
                onPressed: folderId == null
                    ? null
                    : () async {
                        final folder = await context
                            .read<PhylumAccount>()
                            .db
                            .getResource(folderId);
                        if (folder != null && context.mounted) {
                          createDirectory(context, folder);
                        }
                      },
                icon: Icon(Icons.create_new_folder_outlined),
              );
            },
          ),
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
              final name = context.select<ExplorerState, String?>(
                (state) => state.folder?.name,
              );
              return ListTile(
                leading: BackButton(
                  onPressed: () {
                    final parentId = context
                        .read<ExplorerState>()
                        .folder
                        ?.parent;
                    if (parentId != null) {
                      context.read<ExplorerHistoryController>().go(
                        ExplorerLocationFolder(folderId: parentId),
                      );
                      node.requestFocus();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                ),
                title: Text(name ?? ''),
                subtitle: const Text('Pick Destination'),
                trailing: Builder(
                  builder: (context) {
                    final folderId = context.select<ExplorerState, String?>(
                      (state) => state.folderId,
                    );
                    return IconButton(
                      onPressed: folderId == null
                          ? null
                          : () async {
                              final folder = await context
                                  .read<PhylumAccount>()
                                  .db
                                  .getResource(folderId);
                              if (folder != null && context.mounted) {
                                createDirectory(context, folder);
                              }
                            },
                      icon: Icon(Icons.create_new_folder_outlined),
                    );
                  },
                ),
              );
            },
          ),
          content: SizedBox(
            width: 360,
            height: 600,
            child: _buildContents(context),
          ),
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
                  TextButton(
                    onPressed: Navigator.of(context).pop,
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        widget.allowInitialFolder ||
                            context.select<ExplorerState, bool>(
                              (state) =>
                                  state.folderId != widget.initialFolderId,
                            )
                        ? () => Navigator.of(
                            context,
                          ).pop(context.read<ExplorerState>().folderId)
                        : null,
                    child: Text('OK'),
                  ),
                ],
              ),
            ),
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
    final items = context.select<ExplorerState, List<Resource>>(
      (state) => state.resources,
    );
    return Focus(
      autofocus: true,
      focusNode: focusNode,
      child: ExcludeFocus(
        child: ListView.builder(
          itemBuilder: (BuildContext context, int index) {
            final r = items[index];
            return Builder(
              builder: (context) {
                final selected = context.select<ExplorerState, bool>(
                  (state) => state.selectedIds.contains(r.id),
                );
                return ListTile(
                  key: ValueKey(r.id),
                  visualDensity: VisualDensity.compact,
                  selected: selected,
                  leading: r.getIcon(context.read()),
                  title: Text(r.name),
                  enabled: r.dir,
                  onTap: () => context.read<ExplorerHistoryController>().go(
                    ExplorerLocationFolder(folderId: r.id),
                  ),
                );
              },
            );
          },
          itemCount: items.length,
        ),
      ),
    );
  }
}
