import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';

enum MenuOption {
  details(Icons.info_outline, 'Details', isSingle),
  download(Icons.download, 'Download', isFilesOnly),
  copyURL(Icons.link, 'Copy URL', isSingle),
  bookmarkAdd(Icons.bookmark_add_outlined, 'Add Bookmark', notAllBookmarked),
  bookmarkRemove(Icons.bookmark_remove, 'Remove Bookmark', allBookmarked),
  bookmarkEdit(Icons.edit, 'Edit Bookmark', all),
  rename(Icons.drive_file_rename_outline, 'Rename', isSingle),
  move(Icons.drive_file_move_outlined, 'Move To', all),
  copy(Icons.copy, 'Copy To', all),
  delete(Icons.delete_outline, 'Delete', all),
  restore(Icons.restore, 'Restore from Trash', all),
  deleteForever(Icons.delete_forever_outlined, 'Delete Forever', all),
  emptyTrash(Icons.delete_forever_outlined, 'Empty Trash', all),
  permissions(Icons.people_alt_outlined, 'Permissions', isSingle),
  publinks(Icons.public, 'Public Access', isSingle),
  newFolder(Icons.create_new_folder_outlined, 'New Folder', isSingle),
  uploadFiles(Icons.upload_file_outlined, 'Upload File(s)', isSingle),
  uploadFolders(
    Icons.drive_folder_upload_outlined,
    'Upload Folder(s)',
    isSingle,
  ),
  share(Icons.share, 'Share', isFilesOnly),
  iosShare(Icons.ios_share, 'Share', isFilesOnly),
  openFile(Icons.file_open, 'Open', isSingleFile);

  const MenuOption(this.icon, this.text, this.enabled);

  final IconData icon;
  final String text;
  final FutureOr<bool> Function(
    PhylumAccount account,
    Iterable<Resource> resources,
  )
  enabled;
}

bool isSingle(PhylumAccount account, Iterable<Resource> resources) =>
    resources.length == 1;

bool isSingleFile(PhylumAccount account, Iterable<Resource> resources) =>
    resources.length == 1 && !resources.first.dir;

bool none(PhylumAccount account, Iterable<Resource> resources) => false;

bool all(PhylumAccount accout, Iterable<Resource> resources) => true;

bool isFilesOnly(PhylumAccount account, Iterable<Resource> resources) =>
    resources.every((r) => !r.dir);

Future<bool> notAllBookmarked(
  PhylumAccount account,
  Iterable<Resource> resources,
) => allBookmarked(account, resources).then((b) => !b);

Future<bool> allBookmarked(
  PhylumAccount account,
  Iterable<Resource> resources,
) => account.db.bookmarks
    .count(
      where: (b) =>
          b.resourceId.isIn(resources.map((r) => r.id)) &
          b.deleted.equals(false),
    )
    .getSingle()
    .then((c) => c == resources.length);
