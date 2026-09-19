import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/local_upload_errors.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/ui/explorer/util/clipboard.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

class PasteInfo {
  final Iterable<PasteItem> _items;
  Iterable<UploadFile> get files =>
      _items.map((info) => info.file).whereType<UploadFile>();
  Iterable<String> get paths =>
      _items.map((info) => info.path).whereType<String>();
  Iterable<String> get resourceIds =>
      _items.map((info) => info.resourceId).whereType<String>();
  Iterable<String> get errors =>
      _items.map((info) => info.error).whereType<String>();

  PasteInfo(this._items);

  Future<Iterable<Resource>> getResources(PhylumAccount account) async =>
      account.db
          .getResources(resourceIds)
          .then(
            (resources) =>
                resources.whereType<Resource>().toList(growable: false),
          );
}

class PasteItem {
  final UploadFile? file;
  final String? path;
  final String? resourceId;
  final String? error;

  PasteItem.withError({required this.error})
    : file = null,
      path = null,
      resourceId = null;

  PasteItem.withUploadFile({required this.file})
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

// Future<PasteItem> extractPasteItem(
//   PhylumAccount account,
//   DataReader reader,
// ) async {
//   final uri = await reader.readValue(Formats.uri).then((value) => value?.uri);
//   if (uri != null &&
//       (uri.isScheme(account.apiClient.serverUrl.scheme) &&
//           uri.authority == account.apiClient.serverUrl.authority)) {
//     final segments = uri.pathSegments;
//     if (segments.length == 2 &&
//         (segments[0] == 'file' || segments[0] == 'folder')) {
//       return PasteItem.withResourceId(resourceId: segments[1]);
//     }
//   }

//   // TODO: Maybe this needs to be done for all platforms without fs access
//   if (kIsWeb) {
//     final uploadFileCompleter = Completer<UploadFile?>();
//     reader.getFile(null, (file) async {
//       try {
//         uploadFileCompleter.complete(
//           UploadFile(
//             path: file.fileName!,
//             size: file.fileSize!,
//             stream: file.getStream(),
//           ),
//         );
//       } catch (e) {
//         uploadFileCompleter.complete(null);
//       }
//     });
//     final uploadFile = await uploadFileCompleter.future;
//     if (uploadFile != null) return PasteItem.withUploadFile(file: uploadFile);
//   } else {
//     final path = await reader
//         .readValue(Formats.fileUri)
//         .then((value) => value?.toFilePath(windows: Platform.isWindows));
//     if (path != null) {
//       return PasteItem.withPath(path: path);
//     }
//   }

//   return PasteItem.withError(
//     error: await reader.getSuggestedName() ?? 'Unkonwn',
//   );
// }

// Future<PasteInfo> extractPasteInfo(
//   PhylumAccount account,
//   Iterable<DataReader> data,
// ) async {
//   final items = await Future.wait(
//     data.map((item) => extractPasteItem(account, item)),
//   );
//   return PasteInfo(items);
// }

// Future<void> processPasteItems(
//   BuildContext context,
//   String folderId,
//   Iterable<DataReader> data,
// ) async {
//   final account = context.read<PhylumAccount>();
//   final cutIds = context.read<CutToClipboard>().ids;
//   final info = await extractPasteInfo(account, data);
//   final resources = await info.getResources(account);

//   if (!context.mounted) return;

//   if (info.errors.isNotEmpty) {
//     final partial = info.errors.length != info._items.length;
//     final confirm =
//         await showAlertDialog(
//           context,
//           title: 'Unable to import ${partial ? 'some ' : ''}items',
//           message: info.errors.join('\n'),
//           positiveText: partial ? 'Continue' : 'OK',
//           negativeText: partial ? 'Cancel' : null,
//         ) ??
//         false;
//     if (!confirm || !context.mounted) return;
//   }

//   if (!context.mounted) return;
//   await uploadFiles(context, folderId, info.files);
//   if (!context.mounted) return;
//   await uploadPath(context, folderId, info.paths);

//   final copyMoveFn =
//       ListEquality().equals(cutIds, info.resourceIds.toList(growable: false))
//       ? account.resourceRepository.move
//       : account.resourceRepository.copy;
//   for (final r in resources) {
//     if (!context.mounted) return;

//     handleLocalErrors(
//       context,
//       r.name,
//       overwriteFn: (r) => nameConflictDelete,
//       (name, conflictResolution, ensurePermission) => copyMoveFn(
//         resource: r,
//         name: name,
//         parent: folderId,
//         conflictResolution: conflictResolution,
//         ensurePermission: ensurePermission,
//       ),
//     );
//   }
// }

// extension on DataReader {
//   Future<T?> readValue<T extends Object>(ValueFormat<T> format) {
//     final c = Completer<T?>();
//     final value = getValue(
//       format,
//       (value) => c.complete(value),
//       onError: (err) => c.completeError(err),
//     );
//     if (value == null) {
//       return SynchronousFuture(null);
//     }
//     return c.future;
//   }
// }
