import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:provider/provider.dart';

final slashChar = '/'.runes.first;
final illegalChars = <int>{
  ...'\\/:*?"<>|'.runes,
};

bool validateName(String name) =>
    !name.startsWith(' ') &&
    name != '.' &&
    name != '..' &&
    name.trim().isNotEmpty &&
    !name.runes.any((c) => c < 31 || illegalChars.contains(c));

Future<void> createDirectory(BuildContext context, String folderId, {String? preset}) async {
  final account = context.read<PhylumAccount>();
  final name = await showInputDialog(
    context,
    title: 'Create New Folder',
    labelText: 'Folder Name',
    preset: preset,
    validate: validateName,
  );
  if (name == null || !context.mounted) return;
  await handleNameConflict(
    context,
    name,
    overwriteFn: (r) => nameConflictDelete,
    (name, conflictResolution) => account.resourceRepository.mkdir(
      parent: folderId,
      name: name,
      conflictResolution: conflictResolution,
    ),
  );
}

void pickAndUploadFiles(BuildContext context, String folderId) async {
  final files = await openFiles();
  if (!context.mounted) return;
  uploadDirect(context, folderId, files);
}

void uploadDirect(BuildContext context, String folderId, List<XFile> files) async {
  final account = context.read<PhylumAccount>();
  for (final file in files) {
    String? id;
    ensurefile:
    while (id == null) {
      id = await handleNameConflict(
        // ignore: use_build_context_synchronously
        context,
        p.basename(file.name),
        overwriteFn: (r) => r.dir ? nameConflictDelete : nameConflictOverwrite,
        (name, conflictResolution) => account.resourceRepository.upload(
          parent: folderId,
          name: name,
          file: file,
          conflictResolution: conflictResolution,
        ),
      );
      if (id == null && context.mounted) {
        final confirm =
            await showAlertDialog(context, title: 'Skip file?', positiveText: 'No', negativeText: 'Yes') ?? false;
        if (!confirm) break ensurefile;
      }
    }
  }
}

void pickAndUploadDirectory(BuildContext context, String folderId) async {
  final path = await getDirectoryPath();
  if (path == null || !context.mounted) return;
  uploadRecursive(context, folderId, [path]);
}

Future<void> uploadRecursive(BuildContext context, String folderId, Iterable<String> paths) async {
  final account = context.read<PhylumAccount>();
  showProgressDialog(context, message: 'Counting Files');
  DirTree? tree;
  for (final path in paths) {
    final stat = await DirTree.stat(path);
    tree = tree?.mergeWith(stat) ?? stat;
  }

  if (!context.mounted) return;
  Navigator.of(context).pop();

  if (tree == null) return;
  final confirm = await showAlertDialog(
        context,
        title: 'Upload Files?',
        message:
            'Found ${tree.files.length} files and ${tree.dirs.length} directories.\n\nTotal Upload Size: ${tree.totalSize.formatForDisplay()}',
        positiveText: 'YES',
        negativeText: 'NO',
      ) ??
      false;
  if (!confirm || !context.mounted) return;
  final dirIds = <String, String>{};
  for (final path in tree.dirs) {
    final parent = dirIds[p.dirname(path)] ?? folderId;
    String? id;
    while (id == null) {
      id = await handleNameConflict(
        // ignore: use_build_context_synchronously
        context,
        p.basename(path),
        overwriteFn: (r) => nameConflictDelete,
        (name, conflictResolution) => account.resourceRepository.mkdir(
          parent: parent,
          name: name,
          conflictResolution: conflictResolution,
        ),
      );
      if (id == null) {
        if (!context.mounted) return;
        final confirm = await showAlertDialog(context, title: 'Cancel operation?') ?? false;
        if (!confirm) return;
      }
    }
    dirIds[path] = id;
  }

  for (final path in tree.files) {
    final parent = dirIds[p.dirname(path)] ?? folderId;
    String? id;
    ensurefile:
    while (id == null) {
      id = await handleNameConflict(
        // ignore: use_build_context_synchronously
        context,
        p.basename(path),
        overwriteFn: (r) => r.dir ? nameConflictDelete : nameConflictOverwrite,
        (name, conflictResolution) => account.resourceRepository.upload(
          parent: parent,
          name: name,
          path: path,
          conflictResolution: conflictResolution,
        ),
      );
      if (id == null && context.mounted) {
        final confirm =
            await showAlertDialog(context, title: 'Skip file?', positiveText: 'No', negativeText: 'Yes') ?? false;
        if (!confirm) break ensurefile;
      }
    }
  }
}

Future<String?> handleNameConflict(
  BuildContext context,
  String name,
  Future<String> Function(String name, NameConflictResolution conflictResolution) performAction, {
  NameConflictResolution? Function(Resource)? overwriteFn,
}) async {
  NameConflictResolution? conflictResolution = nameConflictError;
  while (conflictResolution != null) {
    try {
      return await performAction(name, conflictResolution);
    } on NameConflictException catch (e) {
      if (!context.mounted) return null;
      final overwrite = overwriteFn?.call(e.resource);
      conflictResolution = await showDialog<NameConflictResolution>(
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
                style: TextButton.styleFrom(foregroundColor: Colors.red),
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
      if (conflictResolution == nameConflictError) {
        if (!context.mounted) return null;
        final newName = await showInputDialog(
          context,
          title: 'Change Name',
          labelText: 'New Name',
          preset: name,
          validate: validateName,
        );
        if (!context.mounted) return null;
        if (newName == null) {
          return null;
        }
        name = newName;
      }
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      if (context.mounted) {
        await showAlertDialog(context, title: 'Unable to create $name', message: e.toString());
      }
      return null;
    }
  }

  return null;
}

class DirTree {
  final int numFiles;
  final int numDirs;
  final int totalSize;
  final List<String> files;
  final List<String> dirs;

  DirTree({
    required this.numFiles,
    required this.numDirs,
    required this.totalSize,
    required this.files,
    required this.dirs,
  });

  DirTree mergeWith(DirTree other) {
    return DirTree(
      numFiles: numFiles + other.numFiles,
      numDirs: numDirs + other.numDirs,
      totalSize: totalSize + other.totalSize,
      files: List.of(files)..addAll(other.files),
      dirs: List.of(dirs)..addAll(other.dirs),
    );
  }

  static Future<DirTree> stat(String path) {
    final s = FileStat.statSync(path);
    if (s.type == FileSystemEntityType.file) {
      return Future.value(DirTree(
        numFiles: 1,
        numDirs: 0,
        totalSize: s.size,
        files: [path],
        dirs: const [],
      ));
    }
    final dir = Directory(path);
    final completer = Completer<DirTree>();
    final files = <String>[];
    final dirs = <String>[path];
    int numFiles = 0;
    int numDirs = 0;
    int totalSize = 0;

    dir.list(recursive: true).listen(
      (file) {
        if (file is File) {
          numFiles++;
          totalSize += file.lengthSync();
          files.add(file.path);
        }
        if (file is Directory) {
          numDirs++;
          dirs.add(file.path);
        }
      },
      onDone: () => completer.complete(DirTree(
        numFiles: numFiles,
        numDirs: numDirs,
        totalSize: totalSize,
        files: files,
        dirs: dirs,
      )),
    );
    return completer.future;
  }
}
