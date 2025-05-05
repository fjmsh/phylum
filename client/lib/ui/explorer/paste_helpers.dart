import 'dart:async';
import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

class PasteInfo {
  final Iterable<PasteItem> _items;
  Iterable<XFile> get files => _items.map((info) => info.file).whereType<XFile>();
  Iterable<String> get paths => _items.map((info) => info.path).whereType<String>();
  Iterable<String> get resourceIds => _items.map((info) => info.resourceId).whereType<String>();
  Iterable<String> get errors => _items.map((info) => info.error).whereType<String>();

  PasteInfo(this._items);

  Future<Iterable<Resource>> getResources(PhylumAccount account) async =>
      account.db.getResources(resourceIds).then((resources) => resources.whereType<Resource>().toList(growable: false));
}

class PasteItem {
  final XFile? file;
  final String? path;
  final String? resourceId;
  final String? error;

  PasteItem.withError({required this.error})
      : file = null,
        path = null,
        resourceId = null;

  PasteItem.withXFile({required this.file})
      : path = null,
        resourceId = null,
        error = null;

  PasteItem.withPath({required this.path})
      : file = null,
        resourceId = null,
        error = null;

  PasteItem.withResourceId({required this.resourceId})
      : file = null,
        path = null,
        error = null;
}

Future<PasteItem> extractPasteItem(PhylumAccount account, DataReader reader) async {
  final uri = await reader.readValue(Formats.uri).then((value) => value?.uri);
  if (uri != null && (uri.isScheme('http') || uri.isScheme('https'))) {
    final openUri = kIsWeb ? Uri.base.replace(path: 'open') : account.apiClient.createUri('/open');
    if (uri.authority == openUri.authority && uri.path == openUri.path && uri.queryParameters.containsKey('id')) {
      final id = uri.queryParameters['id']!;
      return PasteItem.withResourceId(resourceId: id);
    }
  }

// Maybe this needs to be done for all platforms without fs access
  if (kIsWeb) {
    final xfileCompleter = Completer<XFile?>();
    reader.getFile(null, (file) async {
      try {
        final data = await file.readAll();
        xfileCompleter.complete(XFile.fromData(
          data,
          // Setting path on web completely breaks this
          path: kIsWeb ? null : file.fileName,
          name: file.fileName,
          length: data.length,
        ));
      } catch (e) {
        xfileCompleter.complete(null);
      }
    });
    final xfile = await xfileCompleter.future;
    if (xfile != null) return PasteItem.withXFile(file: xfile);
  } else {
    final path =
        await reader.readValue(Formats.fileUri).then((value) => value?.toFilePath(windows: Platform.isWindows));
    if (path != null) {
      return PasteItem.withPath(path: path);
    }
  }

  return PasteItem.withError(error: await reader.getSuggestedName() ?? 'Unkonwn');
}

Future<PasteInfo> extractPasteInfo(PhylumAccount account, Iterable<DataReader> data) async {
  final items = await Future.wait(data.map((item) => extractPasteItem(account, item)));
  return PasteInfo(items);
}

Future<void> processPasteItems(
  BuildContext context,
  String folderId,
  Iterable<DataReader> data, {
  CopyMoveFn? copyMoveFn,
}) async {
  final account = context.read<PhylumAccount>();
  final info = await extractPasteInfo(account, data);
  final resources = await info.getResources(account);

  if (!context.mounted) return;

  if (info.errors.isNotEmpty) {
    final partial = info.errors.length != info._items.length;
    final confirm = await showAlertDialog(
          context,
          title: 'Unable to import ${partial ? 'some ' : ''}items',
          message: info.errors.join('\n'),
          positiveText: partial ? 'Continue' : 'OK',
          negativeText: partial ? 'Cancel' : null,
        ) ??
        false;
    if (!confirm || !context.mounted) return;
  }

  if (!context.mounted) return;
  await uploadXFiles(context, folderId, info.files);
  if (!context.mounted) return;
  await uploadPath(context, folderId, info.paths);

  if (copyMoveFn != null) {
    for (final r in resources) {
      if (!context.mounted) return;

      handleNameConflict(
        context,
        r.name,
        overwriteFn: (r) => nameConflictDelete,
        (name, conflictResolution) => copyMoveFn(
          resource: r,
          name: name,
          parent: folderId,
          conflictResolution: conflictResolution,
        ),
      );
    }
  }
}

extension on DataReader {
  Future<T?> readValue<T extends Object>(ValueFormat<T> format) {
    final c = Completer<T?>();
    final value = getValue(
      format,
      (value) => c.complete(value),
      onError: (err) => c.completeError(err),
    );
    if (value == null) {
      return SynchronousFuture(null);
    }
    return c.future;
  }
}
