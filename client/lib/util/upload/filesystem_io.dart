import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload/upload_utils.dart';
import 'package:path/path.dart' as p;

Future<DirTree> enumerateDirectories(
  BuildContext context,
  Iterable<String> paths,
) async {
  final nav = Navigator.of(context);
  showProgressDialog(context, message: 'Counting Files');

  DirTree tree = DirTree.empty();
  for (final path in paths) {
    final stat = await enumerateDirectory(path);
    tree = tree.mergeWith(stat);
  }

  nav.pop();
  return tree;
}

Future<DirTree> enumerateDirectory(String path) {
  final s = FileStat.statSync(path);
  if (s.type == FileSystemEntityType.file) {
    return Future.value(
      DirTree(
        totalSize: s.size,
        files: [
          UploadFile(
            size: s.size,
            stream: File(path).openRead().cast<Uint8List>(),
            path: p.basename(path),
          ),
        ],
        dirs: const [],
      ),
    );
  }
  final dir = Directory(path);
  final completer = Completer<DirTree>();
  final files = <UploadFile>[];
  final dirs = <String>[p.basename(path)];
  int totalSize = 0;

  final prefixLen = p.dirname(path).length + 1;

  dir.list(recursive: true).listen(
    (file) {
      if (file is File) {
        totalSize += file.lengthSync();
        files.add(
          UploadFile(
            size: file.lengthSync(),
            stream: File(file.path).openRead().cast<Uint8List>(),
            path: file.path.substring(prefixLen),
          ),
        );
      }
      if (file is Directory) {
        dirs.add(file.path.substring(prefixLen));
      }
    },
    onDone: () => completer.complete(
      DirTree(totalSize: totalSize, files: files, dirs: dirs),
    ),
  );
  return completer.future;
}
