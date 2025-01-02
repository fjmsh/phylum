import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_bind.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/libphylum/util/uuid.dart';
import 'package:provider/provider.dart';

final slashChar = '/'.runes.first;
final illegalChars = <int>{
  ...'\\/:*?"<>|'.runes,
};

bool validateName(String name) =>
    !name.startsWith(' ') && name != '.' && name != '..' && name.trim().isNotEmpty && !name.runes.any((c) => c < 31 || illegalChars.contains(c));

void createDirectory(BuildContext context, String folderId) async {
  final account = context.read<PhylumAccount>();
  final dirName = await showInputDialog(
    context,
    title: 'Create New Folder',
    labelText: 'Folder Name',
    validate: validateName,
  );
  if (dirName == null || dirName == "") return;
  account.addAction(ResourceMkdirAction(resourceId: generateUuid(), parent: folderId, resourceName: dirName));
}

void pickAndUploadFiles(BuildContext context, String folderId) async {
  final files = await openFiles();
  if (!context.mounted) return;
  uploadRecursive(context, folderId, files.map((f) => f.path));
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
        message: 'Found ${tree.files.length} files and ${tree.dirs.length} directories.\n\nTotal Upload Size: ${tree.totalSize.formatForDisplay()}',
        positiveText: 'YES',
        negativeText: 'NO',
      ) ??
      false;
  if (!confirm || !context.mounted) return;
  final dirIds = <String, String>{};
  for (final dir in tree.dirs) {
    dirIds[dir] = generateUuid();
    final parent = p.dirname(dir);
    account.addAction(ResourceMkdirAction(resourceId: dirIds[dir]!, parent: dirIds[parent] ?? folderId, resourceName: p.basename(dir)));
  }
  for (final file in tree.files) {
    final parent = p.dirname(file);
    final action = await ResourceUploadAction.fromPath(
      parent: dirIds[parent] ?? folderId,
      resourceName: p.basename(file),
      path: file,
      conflictResolution: resourceBindConflictResolutionError,
    );
    await account.addAction(action);
  }
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
