import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_copy.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:phylum/libphylum/util/uuid.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

void handlePasteAction(PasteFromClipboardIntent i, BuildContext context) async {
  final account = context.read<PhylumAccount>();
  final controller = context.read<ExplorerViewState>();
  final target = controller.folder;
  if (target == null) {
    return;
  }
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
    item.getValue(
      Formats.fileUri,
      (value) => c.complete(value?.toFilePath(windows: Platform.isWindows)),
      onError: (value) => c.complete(null),
    );
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
  uploadRecursive(context, target.id, paths);
  for (final r in cutResources) {
    account.addAction(ResourceMoveAction(r: r, parent: target.id));
  }
  for (final r in copyResources) {
    account.addAction(ResourceCopyAction(
      src: r,
      resourceId: generateUuid(),
      resourceName: r.name,
      parentId: target.id,
    ));
  }

  await SystemClipboard.instance?.write([]);

  return null;
}
