import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/local_upload_errors.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/util/clipboard.dart';
import 'package:phylum/util/clippy/clippy.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

Future<void> pasteItems(
  BuildContext context,
  String folderId,
  PasteData data,
) async {
  switch (data) {
    case PasteError(error: String? error, details: String? details):
      showAlertDialog(context, title: error, message: details);
      break;
    case PasteFilesData():
      await uploadFiles(context, folderId, data.files);
      break;
    case PasteResourcesData():
      final account = context.read<PhylumAccount>();
      final cutIds = context.read<CutToClipboard>().ids;
      final copyMoveFn =
          ListEquality().equals(cutIds, data.ids.toList(growable: false))
          ? account.resourceRepository.move
          : account.resourceRepository.copy;

      for (final r in await data.getResources(account)) {
        if (!context.mounted) return;

        handleLocalErrors(
          context,
          r.name,
          overwriteFn: (r) => nameConflictDelete,
          (name, conflictResolution, ensurePermission) => copyMoveFn(
            resource: r,
            name: name,
            parent: folderId,
            conflictResolution: conflictResolution,
            ensurePermission: ensurePermission,
          ),
        );
      }
  }
}
