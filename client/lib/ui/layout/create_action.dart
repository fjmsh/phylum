import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/app/shortcuts.dart';

enum CreateAction {
  newFolder(descripiton: 'New Folder', icon: Icon(Icons.create_new_folder), intent: NewFolderIntent()),
  uploadFiles(descripiton: 'Upload File(s)', icon: Icon(Icons.upload_file_rounded), intent: UploadFilesIntent()),
  uploadFolders(
      descripiton: 'Upload Folder(s)', icon: Icon(Icons.drive_folder_upload_rounded), intent: UploadFolderIntent());

  final String descripiton;
  final Icon icon;
  final Intent intent;

  const CreateAction({required this.descripiton, required this.icon, required this.intent});
}

List<CreateAction?> getCreateActions(BuildContext context) {
  if (kIsWeb || Platform.isAndroid) {
    return const [
      CreateAction.newFolder,
      CreateAction.uploadFiles,
    ];
  }
  return const [
    CreateAction.newFolder,
    null,
    CreateAction.uploadFiles,
    CreateAction.uploadFolders,
  ];
}
