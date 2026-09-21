import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:phylum/util/upload/filesystem_io.dart';
import 'package:phylum/util/upload/upload_utils.dart';

bool get folderUploadSupported => !Platform.isAndroid;

Future<void> pickAndUploadDirectory(
  BuildContext context,
  String folderId,
) async {
  final path = await FilePicker.getDirectoryPath();
  if (path == null || !context.mounted) return;
  final tree = await enumerateDirectories(context, [path]);
  if (!context.mounted) return;
  return uploadDirTree(context, folderId, tree);
}
