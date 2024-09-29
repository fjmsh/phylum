import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/preview/resource_preview.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'explorer_view_controller.dart';

class ExplorerActions extends StatelessWidget {
  final Widget child;

  const ExplorerActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        FocusUpIntent: CallbackAction<FocusUpIntent>(onInvoke: (i) {
          context.read<ExplorerViewController>().updateSelection((i) => i - 1, i.mode, true);
          return null;
        }),
        FocusDownIntent: CallbackAction<FocusDownIntent>(onInvoke: (i) {
          context.read<ExplorerViewController>().updateSelection((i) => i + 1, i.mode, true);
          return null;
        }),
        ToggleSelectionIntent: CallbackAction<ToggleSelectionIntent>(onInvoke: (i) {
          context.read<ExplorerViewController>().updateSelection((i) => i, SelectionMode.toggle, true);
          return null;
        }),
        SelectAllIntent: CallbackAction<SelectAllIntent>(onInvoke: (i) {
          context.read<ExplorerViewController>().selectAll(showFocus: true);
          return null;
        }),
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) {
          context.read<ExplorerViewController>().updateSelection((i) => i, SelectionMode.single, true);
          return null;
        }),
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (i) {
          final r = context.read<ExplorerViewState>().selectedSingle;
          if (r == null) return;
          _openResource(context, r);
          return null;
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (i) {
          final selected = context.read<ExplorerViewState>().selected;
          _deleteResources(context, selected);
          return null;
        }),
        RenameIntent: CallbackAction<RenameIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final r = context.read<ExplorerViewState>().selectedSingle;
          if (r == null) return;
          final name = await showInputDialog(context, title: 'Rename', preset: r.name);
          if (name != null) {
            account.addAction(ResourceMoveAction(r: r, name: name));
          }
          return null;
        }),
        CopyToClipboardIntent: CallbackAction<CopyToClipboardIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final selected = context.read<ExplorerViewState>().selected;
          final items = selected.map((r) {
            final uri = account.apiClient.createUriBuilder('/open');
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
          final folderId = context.read<ExplorerViewController>().folderId;
          final openUri = account.apiClient.createUri('/open');
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
          uploadRecursive(context, folderId, paths);
          final parent = await account.resourceRepository.getResource(folderId);
          if (parent != null) {
            for (final r in cutResources) {
              account.addAction(ResourceMoveAction(r: r, parent: parent));
            }
          }

          await SystemClipboard.instance?.write([]);

          return null;
        }),
      },
      child: child,
    );
  }

  void _openResource(BuildContext context, Resource r) {
    if (r.dir) {
      context.pushNamed('folder', pathParameters: {'id': r.id});
    } else {
      ResourcePreview.showPreview(context, r.id);
    }
  }

  void _deleteResources(BuildContext context, Iterable<Resource> resources) async {
    final account = context.read<PhylumAccount>();
    // TOOD: #folderconfirmation
    final confirm =
        await showAlertDialog(context, title: 'Delete selected items?', barrierDismissible: true, positiveText: 'YES', negativeText: 'NO') ?? false;

    if (!confirm) return;
    for (final r in resources) {
      account.addAction(ResourceDeleteAction(r: r));
    }
  }
}
