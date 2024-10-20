import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_copy.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'explorer_view_controller.dart';
import 'folder_empty_view.dart';
import 'folder_list_view.dart';

class ExplorerView extends StatelessWidget {
  const ExplorerView._({super.key});

  static Widget create(String folderId) {
    return Builder(builder: (context) {
      return ListTileTheme(
        data: ListTileThemeData(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.basic),
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: StateNotifierProvider<ExplorerViewController, ExplorerViewState>(
          create: (context) => ExplorerViewController(account: context.read<PhylumAccount>(), folderId: folderId),
          child: Actions(
            actions: {
              NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
              PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
              PasteFromClipboardIntent: CallbackAction<PasteFromClipboardIntent>(onInvoke: (i) async {
                // TODO: Move to top-level nav
                final account = context.read<PhylumAccount>();
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
                  for (final r in copyResources) {
                    account.addAction(ResourceCopyAction(
                      src: r,
                      resourceId: generateId(),
                      resourceName: r.name,
                      parentId: parent.id,
                    ));
                  }
                }

                await SystemClipboard.instance?.write([]);

                return null;
              }),
            },
            child: ExplorerView._(key: ValueKey(folderId)),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = context.select<ExplorerViewState, FolderEmptyViewType?>((state) {
      if (state.resources.isEmpty) {
        if (state.refreshing) {
          return FolderEmptyViewType.loading;
        }
        if (state.refreshError) {
          return FolderEmptyViewType.error;
        }
        return FolderEmptyViewType.noData;
      }
      return null;
    });
    if (type != null) {
      return FolderEmptyView(
        type: type,
        onRefresh: context.read<ExplorerViewController>().refresh,
      );
    }
    return RefreshIndicator(
      onRefresh: context.read<ExplorerViewController>().refresh,
      child: const FolderListView(),
    );
  }
}
