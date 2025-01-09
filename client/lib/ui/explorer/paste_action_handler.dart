import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/explorer/explorer_controller.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

void handlePasteAction(PasteFromClipboardIntent i, BuildContext context) async {
  final account = context.read<PhylumAccount>();
  final folderId = context.read<ExplorerState>().folderId;
  if (folderId == null) {
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
          final resource = await account.db.getResource(resourceId);
          if (resource != null) {
            (cut ? cutResources : copyResources).add(resource);
          }
        }
      }
    }
  }
  if (!context.mounted) return;
  uploadRecursive(context, folderId, paths);
  for (final r in cutResources) {
    handleNameConflict(
      context,
      r.name,
      overwriteFn: (r) => nameConflictDelete,
      (name, conflictResolution) => account.resourceRepository.move(
        resource: r,
        name: name,
        parent: folderId,
        conflictResolution: conflictResolution,
      ),
    );
  }
  for (final r in copyResources) {
    handleNameConflict(
      context,
      r.name,
      overwriteFn: (r) => nameConflictDelete,
      (name, conflictResolution) => account.resourceRepository.copy(
        resource: r,
        name: name,
        parent: folderId,
        conflictResolution: conflictResolution,
      ),
    );
  }

  await SystemClipboard.instance?.write([]);

  return null;
}
