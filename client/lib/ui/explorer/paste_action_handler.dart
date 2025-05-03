import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/app/app_shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

void handlePasteAction(PasteFromClipboardIntent i, BuildContext context) async {
  final account = context.read<PhylumAccount>();
  final folderId = context.read<ExplorerState>().folderId;
  if (folderId == null) {
    return;
  }
  final openUri = kIsWeb ? Uri.base.replace(path: 'open') : account.apiClient.createUri('/open');
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return;
  }
  final reader = await clipboard.read();
  final paths = <String>[];
  final ids = <String>[];
  var copyFn = account.resourceRepository.copy;

  for (final item in reader.items) {
    final filePath =
        await item.readValue(Formats.fileUri).then((value) => value?.toFilePath(windows: Platform.isWindows));
    if (filePath != null) {
      assert(ids.isEmpty);
      paths.add(filePath);
    } else {
      assert(paths.isEmpty);
      final uri = await item.readValue(Formats.uri).then((value) => value?.uri);
      if (uri != null) {
        if (uri.authority == openUri.authority && uri.path == openUri.path && uri.queryParameters.containsKey('id')) {
          ids.add(uri.queryParameters['id']!);
          if (uri.queryParameters.containsKey('cut')) {
            copyFn = account.resourceRepository.move;
          }
        }
      }
    }
  }
  if (!context.mounted) return;
  if (paths.isNotEmpty) {
    uploadRecursive(context, folderId, paths);
  }
  final resources =
      await account.db.getResources(ids).then((resources) => resources.whereType<Resource>().toList(growable: false));
  if (!context.mounted) return;
  for (final r in resources) {
    handleNameConflict(
      context,
      r.name,
      overwriteFn: (r) => nameConflictDelete,
      (name, conflictResolution) => copyFn(
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
