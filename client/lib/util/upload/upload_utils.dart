import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/local_upload_errors.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:provider/provider.dart';

final slashChar = '/'.runes.first;
final illegalChars = <int>{...'\\/:*?"<>|'.runes};

bool validateName(String name) =>
    !name.startsWith(' ') &&
    name != '.' &&
    name != '..' &&
    name.trim().isNotEmpty &&
    !name.runes.any((c) => c < 31 || illegalChars.contains(c));

Future<void> createDirectory(
  BuildContext context,
  Resource parent, {
  String? preset,
}) async {
  final account = context.read<PhylumAccount>();
  final name = await showInputDialog(
    context,
    title: 'Create New Folder',
    labelText: 'Folder Name',
    preset: preset,
    validate: validateName,
  );
  if (name == null || !context.mounted) return;
  await handleLocalErrors(
    context,
    name,
    overwriteFn: (r) => nameConflictDelete,
    (name, conflictResolution, ensurePermission) =>
        account.resourceRepository.mkdir(
          parent: parent.id,
          name: name,
          userPermission: parent.userPermission,
          conflictResolution: conflictResolution,
          ensurePermission: ensurePermission,
        ),
  );
}

Future<void> pickAndUploadFiles(BuildContext context, String folderId) async {
  final result = await FilePicker.pickFiles();
  if (!context.mounted || result.isEmpty) return;

  final files = result
      .map((e) {
        final stream = e.readAsByteStream();
        return UploadFile(
          size: e.lengthSync() ?? 0,
          stream: stream.cast(),
          path: e.name,
        );
      })
      .whereType<UploadFile>()
      .toList(growable: false);

  final tree = DirTree(
    totalSize: files.map((f) => f.size).fold(0, (acc, s) => acc + s),
    files: files,
    dirs: const [],
  );
  return uploadDirTree(context, folderId, tree);
}

Future<void> pickAndUploadVersion(
  BuildContext context,
  Resource resource,
) async {
  final account = context.read<PhylumAccount>();
  final result = await FilePicker.pickFile();
  if (result == null) return;

  final pickedFile = result;
  final stream = pickedFile.readAsByteStream();
  final file = UploadFile(
    size: pickedFile.lengthSync() ?? 0,
    stream: stream.cast(),
    path: pickedFile.name,
  );

  try {
    account.resourceRepository.uploadVersion(
      resource: resource,
      contents: file.stream,
      size: file.size,
      userPermission: resource.userPermission,
    );
  } on PermissionException {
    if (context.mounted) {
      await showAlertDialog(
        context,
        title: 'Permissions Error',
        message:
            'You do not have permissions to upload a new version of this file.',
        positiveText: 'Okay',
        negativeText: 'Try Anyway',
      );
    }
  }
}

Future<void> uploadDirTree(
  BuildContext context,
  String folderId,
  DirTree tree,
) async {
  if (tree.files.isEmpty && tree.dirs.isEmpty) return;
  final title = tree.files.length == 1
      ? 'Upload File?'
      : 'Upload ${tree.files.length} files?';
  String message = '${tree.totalSize.formatForDisplay()} will be uploaded.';
  if (tree.dirs.isNotEmpty) {
    message += '\n\n${tree.dirs.length} directories will be created.';
  }
  final confirm =
      await showAlertDialog(
        context,
        title: title,
        message: message,
        positiveText: 'YES',
        negativeText: 'NO',
      ) ??
      false;
  if (!confirm || !context.mounted) return;

  final account = context.read<PhylumAccount>();
  final userPermission =
      await account.db.getResource(folderId).then((r) => r?.userPermission) ??
      0;
  final dirIds = <String, String>{};
  for (final path in tree.dirs) {
    final parent = dirIds[p.dirname(path)] ?? folderId;
    String? id;
    while (id == null) {
      id = await handleLocalErrors(
        // ignore: use_build_context_synchronously
        context,
        p.basename(path),
        overwriteFn: (r) => nameConflictDelete,
        (name, conflictResolution, ensurePermission) =>
            account.resourceRepository.mkdir(
              parent: parent,
              name: name,
              userPermission: userPermission,
              conflictResolution: conflictResolution,
              ensurePermission: ensurePermission,
            ),
      );
      if (id == null) {
        if (!context.mounted) return;
        final confirm =
            await showAlertDialog(
              context,
              title: 'Cancel operation?',
              positiveText: 'No',
              negativeText: 'Yes',
            ) ??
            false;
        if (!confirm) return;
      }
    }
    dirIds[path] = id;
  }

  for (final file in tree.files) {
    final parent = dirIds[p.dirname(file.path)] ?? folderId;
    String? id;
    ensurefile:
    while (id == null) {
      id = await handleLocalErrors(
        // ignore: use_build_context_synchronously
        context,
        p.basename(file.path),
        overwriteFn: (r) => r.dir ? nameConflictDelete : nameConflictOverwrite,
        (name, conflictResolution, ensurePermission) {
          return account.resourceRepository.upload(
            parent: parent,
            name: name,
            contents: file.stream,
            size: file.size,
            userPermission: userPermission,
            conflictResolution: conflictResolution,
            ensurePermission: ensurePermission,
          );
        },
      );
      if (id == null && context.mounted) {
        final confirm =
            await showAlertDialog(
              context,
              title: 'Skip file?',
              positiveText: 'No',
              negativeText: 'Yes',
            ) ??
            false;
        if (!confirm) break ensurefile;
      }
    }
  }
}

Future<String?> handleLocalErrors(
  BuildContext context,
  String name,
  Future<String> Function(String, NameConflictResolution, bool) performAction, {
  NameConflictResolution? Function(Resource)? overwriteFn,
  NameConflictResolution conflictResolution = nameConflictError,
  bool ensurePermission = true,
}) async {
  try {
    return await performAction(name, conflictResolution, ensurePermission);
  } on PermissionException {
    if (!context.mounted) return null;
    final skip =
        await showAlertDialog(
          context,
          title: 'Permissions Error',
          message: 'You do not have permissions to write to this folder.',
          positiveText: 'OK',
          negativeText: 'Try Anyway',
        ) ??
        true;
    if (!skip && context.mounted) {
      return handleLocalErrors(
        context,
        name,
        performAction,
        overwriteFn: overwriteFn,
        conflictResolution: conflictResolution,
        ensurePermission: false,
      );
    }
  } on NameConflictException catch (e) {
    if (!context.mounted) return null;
    final overwrite = overwriteFn?.call(e.resource);
    final newResolution = await showDialog<NameConflictResolution>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Name Conflict'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Text(
            'There is already another item with the name \'$name\' in this folder.',
            softWrap: true,
          ),
        ),
        actions: <Widget>[
          if (overwrite != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Overwrite'),
              onPressed: () {
                Navigator.of(context).pop(overwrite);
              },
            ),
          TextButton(
            child: const Text('Change Name'),
            onPressed: () {
              Navigator.of(context).pop(nameConflictError);
            },
          ),
          ElevatedButton(
            autofocus: true,
            child: const Text('Auto Rename'),
            onPressed: () {
              Navigator.of(context).pop(nameConflictRename);
            },
          ),
        ],
      ),
    );
    if (newResolution == null) {
      return null;
    }
    if (newResolution == nameConflictError) {
      if (!context.mounted) return null;
      final newName = await showInputDialog(
        context,
        title: 'Change Name',
        labelText: 'New Name',
        preset: name,
        validate: validateName,
      );
      if (newName == null) {
        return null;
      }
      name = newName;
    }
    if (!context.mounted) return null;
    return handleLocalErrors(
      context,
      name,
      performAction,
      overwriteFn: overwriteFn,
      conflictResolution: newResolution,
      ensurePermission: ensurePermission,
    );
  } on DestinationCycleException catch (e) {
    if (context.mounted) {
      await showAlertDialog(
        context,
        message: 'Cannot move ${e.resource.name} into itself',
      );
    }
  } catch (e) {
    if (context.mounted) {
      await showAlertDialog(
        context,
        title: 'Unable to create $name',
        message: e.toString(),
      );
    }
  }

  return null;
}

class DirTree {
  final int totalSize;
  final List<UploadFile> files;
  final List<String> dirs;

  const DirTree({
    required this.totalSize,
    required this.files,
    required this.dirs,
  });

  const DirTree.empty() : this(totalSize: 0, files: const [], dirs: const []);

  DirTree mergeWith(DirTree other) {
    return DirTree(
      totalSize: totalSize + other.totalSize,
      files: List.of(files)..addAll(other.files),
      dirs: List.of(dirs)..addAll(other.dirs),
    );
  }

  @override
  String toString() {
    final sb = StringBuffer('DirTree(totalSize: $totalSize)\n');
    sb.write('${dirs.length} dirs:\n');
    for (final dir in dirs) {
      sb.write('$dir\n');
    }
    sb.write('${files.length} files:\n');
    for (final file in files) {
      sb.write('${file.path}\n');
    }
    return sb.toString();
  }
}
