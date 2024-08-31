import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_mkdir.dart';
import 'package:phylum/libphylum/actions/action_resource_upload.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/file_size.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

void createDirectory(BuildContext context, String folderId) async {
  final account = context.read<PhylumAccount>();
  final dirName = await showInputDialog(context, title: 'Create New Folder', labelText: 'Folder Name');
  if (dirName == null || dirName == "") return;
  account.addAction(ResourceMkdirAction(id: uuid.v4(), parent: folderId, resourceName: dirName));
}

void pickAndUploadFiles(BuildContext context, String folderId) async {
  final account = context.read<PhylumAccount>();
  final files = await openFiles();
  for (final file in files) {
    final action = await ResourceUploadAction.fromPath(parent: folderId, resourceName: file.name, path: file.path);
    await account.addAction(action);
  }
}

void pickAndUploadDirectory(BuildContext context, String folderId) async {
  final account = context.read<PhylumAccount>();
  final path = await getDirectoryPath();
  if (path == null) return;
  if (!context.mounted) return;
  showProgressDialog(context, message: 'Counting Files');
  final tree = await DirTree.stat(path);

  if (!context.mounted) return;
  Navigator.of(context).pop();
  final confirm = await showAlertDialog(
        context,
        title: 'Upload Folder?',
        message: 'Found ${tree.files.length} files and ${tree.dirs.length} directories.\n\nTotal Upload Size: ${tree.totalSize.getHumanString()}',
        positiveText: 'YES',
        negativeText: 'NO',
      ) ??
      false;
  if (!confirm || !context.mounted) return;
  final dirIds = <String, String>{};
  dirIds[path] = uuid.v4();
  account.addAction(ResourceMkdirAction(id: dirIds[path]!, parent: folderId, resourceName: p.basename(path)));
  for (final dir in tree.dirs) {
    dirIds[dir] = uuid.v4();
    final parent = p.dirname(dir);
    account.addAction(ResourceMkdirAction(id: dirIds[dir]!, parent: dirIds[parent]!, resourceName: p.basename(dir)));
  }
  for (final file in tree.files) {
    final parent = p.dirname(file);
    final action = await ResourceUploadAction.fromPath(parent: dirIds[parent]!, resourceName: p.basename(file), path: file);
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

  static Future<DirTree> stat(String path) {
    final dir = Directory(path);
    final completer = Completer<DirTree>();
    final files = <String>[];
    final dirs = <String>[];
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
