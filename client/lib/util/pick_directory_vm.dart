import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:phylum/util/upload_utils.dart';

bool get folderUploadSupported => !Platform.isAndroid;

Future<void> pickAndUploadDirectory(
    BuildContext context, String folderId) async {
  final path = await FilePicker.getDirectoryPath();
  if (path == null || !context.mounted) return;
  return uploadPath(context, folderId, [path]);
}
