import 'package:flutter/material.dart';
import 'package:phylum/ui/app/app_shortcuts.dart';

enum FabAction {
  newFolder(descripiton: 'New Folder', icon: Icon(Icons.create_new_folder), intent: NewFolderIntent()),
  uploadFiles(descripiton: 'Upload File(s)', icon: Icon(Icons.upload_file_rounded), intent: UploadFilesIntent()),
  uploadFolders(
      descripiton: 'Upload Folder(s)', icon: Icon(Icons.drive_folder_upload_rounded), intent: UploadFolderIntent());

  final String descripiton;
  final Icon icon;
  final Intent intent;

  const FabAction({required this.descripiton, required this.icon, required this.intent});
}

final popupMenuActions = [
  FabAction.newFolder,
  null,
  FabAction.uploadFiles,
  FabAction.uploadFolders,
];
