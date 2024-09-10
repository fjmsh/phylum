import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/folder/folder_selection_manager.dart';
import 'package:phylum/ui/folder/resource_details_row.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

class FolderContentsView extends StatefulWidget {
  final String folderId;
  final List<Resource> resources;

  FolderContentsView({required this.folderId, required this.resources}) : super(key: ValueKey(folderId));

  @override
  State<FolderContentsView> createState() => _FolderContentsViewState();
}

class _FolderContentsViewState extends State<FolderContentsView> {
  final Map<String, FocusNode> nodes = {};
  late List<Resource> resources;
  int focusIndex = -1;
  int selectionStartIndex = -1;

  @override
  void initState() {
    super.initState();
    resources = widget.resources;
  }

  @override
  void didUpdateWidget(covariant FolderContentsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selection = context.read<FolderSelectionState>();

    final extras = Set.of(selection.selected);
    extras.removeAll(widget.resources);
    final selected = Set.of(selection.selected);
    selected.removeAll(extras);

    // selection.
    focusIndex = widget.resources.indexWhere((r) => r.id == selection.focusId);
    WidgetsBinding.instance.addPostFrameCallback((duration) => context.read<FolderSelectionManager>().update(
          focusId: focusIndex == -1 ? "" : null,
          selected: selected,
        ));

    setState(() => resources = widget.resources);
  }

  @override
  void dispose() {
    for (final n in nodes.values) {
      n.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        FocusUpIntent: CallbackAction<FocusUpIntent>(onInvoke: (i) {
          if (resources.isEmpty) return;
          final index = focusIndex == -1
              ? (resources.length - 1)
              : focusIndex > 0
                  ? min(focusIndex - 1, resources.length - 1)
                  : 0;
          updateSelection(index, i.mode, true);
          return null;
        }),
        FocusDownIntent: CallbackAction<FocusDownIntent>(onInvoke: (i) {
          if (resources.isEmpty) return;
          final index = min(focusIndex + 1, resources.length - 1);
          updateSelection(index, i.mode, true);
          return null;
        }),
        ToggleSelectionIntent: CallbackAction<ToggleSelectionIntent>(onInvoke: (i) {
          updateSelection(focusIndex, SelectionMode.toggle, true);
          return null;
        }),
        SelectAllIntent: CallbackAction<SelectAllIntent>(onInvoke: (i) {
          context.read<FolderSelectionManager>().update(selected: Set.of(resources.map((r) => r.id)), showFocus: true);
          return null;
        }),
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) {
          if (focusIndex >= 0) {
            updateSelection(focusIndex, SelectionMode.single, true);
          } else {
            context.read<FolderSelectionManager>().update(selected: const {}, showFocus: true);
          }
          return null;
        }),
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (i) {
          open(resources[focusIndex]);
          return null;
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (i) {
          deleteSelected();
          return null;
        }),
        CopyToClipboardIntent: CallbackAction<CopyToClipboardIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final selectedIds = context.read<FolderSelectionState>().selected;
          if (selectedIds.isEmpty) return;
          final selected = resources.where((r) => selectedIds.contains(r.id)).toList(growable: false);
          final items = selected.map((r) {
            final uri = account.api.createUriBuilder('/open');
            uri.queryParameters['id'] = r.id;
            if (i.cut) {
              uri.queryParameters['cut'] = 'y';
            }
            final uriData = Formats.uri(NamedUri(uri.build(), name: r.name));
            return DataWriterItem(suggestedName: r.name)..add(uriData);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${items.length} items ${i.cut ? 'cut' : 'copied'} to clipboard')));
          await SystemClipboard.instance?.write(items);
          return null;
        }),
        PasteFromClipboardIntent: CallbackAction<PasteFromClipboardIntent>(onInvoke: (i) async {
          // TODO: Move to top-level nav
          final account = context.read<PhylumAccount>();
          final openUri = account.api.createUri('/open');
          final clipboard = SystemClipboard.instance;
          if (clipboard == null) {
            return;
          }
          final reader = await clipboard.read();
          final paths = <String>[];
          final cutResources = <Resource>[];
          final copyResources = <Resource>[];
          for (final item in reader.items) {
            final c = Completer<String?>();
            item.getValue(Formats.fileUri, (value) => c.complete(value?.toFilePath()), onError: (value) => c.complete(null));
            final filePath = await c.future;
            if (filePath != null) {
              paths.add(filePath);
            } else {
              final c = Completer<Uri?>();
              item.getValue(Formats.uri, (value) {
                c.complete(value?.uri);
              }, onError: (value) => c.complete(null));
              final uri = await c.future;
              if (uri != null) {
                if (uri.authority == openUri.authority && uri.path == openUri.path && uri.queryParameters.containsKey('id')) {
                  final resourceId = uri.queryParameters['id']!;
                  final cut = uri.queryParameters.containsKey('cut');
                  final resource = await account.resourceRepository.getResource(resourceId);
                  if (resource != null) {
                    (cut ? cutResources : copyResources).add(resource);
                  }
                }
              }
            }
          }
          if (!context.mounted) return;
          uploadRecursive(context, widget.folderId, paths);
          final parent = await account.resourceRepository.getResource(widget.folderId);
          if (parent != null) {
            for (final r in cutResources) {
              account.addAction(ResourceMoveAction(r: r, parent: parent));
            }
          }

          await SystemClipboard.instance?.write([]);

          return null;
        }),
      },
      child: Focus(
        autofocus: true,
        descendantsAreFocusable: false,
        child: ListView.builder(
          itemCount: resources.length,
          itemBuilder: (context, index) {
            final r = resources[index];
            bool deferHandling = false;
            return ResourceDetailsRow(
                r: r,
                onTapDown: (details) {
                  final mode = HardwareKeyboard.instance.isControlPressed
                      ? SelectionMode.toggle
                      : HardwareKeyboard.instance.isShiftPressed
                          ? SelectionMode.range
                          : SelectionMode.single;
                  if (context.read<FolderSelectionState>().isSelected(r.id) && mode == SelectionMode.single) {
                    deferHandling = true;
                    context.read<FolderSelectionManager>().update(focusId: r.id, showFocus: false);
                  } else {
                    deferHandling = false;
                    updateSelection(index, mode, false);
                  }
                },
                onTap: () {
                  if (deferHandling) {
                    updateSelection(index, SelectionMode.single, false);
                  }
                },
                onDoubleTap: () => open(r));
          },
        ),
      ),
    );
  }

  void updateSelection(int index, SelectionMode mode, bool highlight) {
    Set<String>? selected;
    switch (mode) {
      case SelectionMode.range:
        if (selectionStartIndex == -1) {
          selectionStartIndex = index;
        }
        selected = Set.of(resources.getRange(min(selectionStartIndex, index), max(selectionStartIndex, index) + 1).map((r) => r.id));
        break;
      case SelectionMode.single:
        selected = {resources[index].id};
        selectionStartIndex = index;
        break;
      case SelectionMode.toggle:
        selected = Set.of(context.read<FolderSelectionState>().selected);
        if (!selected.add(resources[index].id)) {
          selected.remove(resources[index].id);
        }
        selectionStartIndex = index;
        break;
      case SelectionMode.multi:
        break;
    }
    focusIndex = index;
    context
        .read<FolderSelectionManager>()
        .update(selected: selected, focusId: index < resources.length ? resources[index].id : null, showFocus: highlight);
  }

  void open(Resource r) {
    if (r.dir) context.goNamed('folder', pathParameters: {'id': r.id});
  }

  void deleteSelected() async {
    final selectedIds = context.read<FolderSelectionState>().selected;
    if (selectedIds.isEmpty) return;
    final account = context.read<PhylumAccount>();
    final selected = resources.where((r) => selectedIds.contains(r.id)).toList(growable: false);
    final confirm = await showAlertDialog(context,
            title: 'Delete ${selectedIds.length} files?', barrierDismissible: true, positiveText: 'YES', negativeText: 'NO') ??
        false;

    if (!confirm) return;
    for (final r in selected) {
      account.addAction(ResourceDeleteAction(r: r));
    }
  }
}
