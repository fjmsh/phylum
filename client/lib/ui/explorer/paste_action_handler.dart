import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_copy.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

class PasteActionHandler extends StatelessWidget {
  final String folderId;
  final Widget child;

  const PasteActionHandler({super.key, required this.folderId, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        PasteFromClipboardIntent: CallbackAction<PasteFromClipboardIntent>(onInvoke: (i) async {
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
      child: child,
    );
  }
}
