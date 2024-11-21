import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/actions/bookmark_add_action.dart';
import 'package:phylum/libphylum/actions/bookmark_remove_action.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

enum MenuOption {
  details(Icons.info_outline, 'Details', isSingle),
  download(Icons.download, 'Download', isFilesOnly),
  bookmarkAdd(Icons.bookmark_add_outlined, 'Add To Bookmarks', notAllBookmarked),
  bookmarkRemove(Icons.bookmark_remove, 'Remove From Bookmarks', allBookmarked),
  rename(Icons.drive_file_rename_outline, 'Rename', isSingle),
  move(Icons.drive_file_move_outlined, 'Move To', all),
  copy(Icons.copy, 'Copy To', all),
  delete(Icons.delete_outline, 'Delete', all),
  permissions(Icons.people_alt_outlined, 'Permissions', isSingle),
  publinks(Icons.public, 'Public Access', isSingle),
  newFolder(Icons.create_new_folder_outlined, 'New Folder', isSingle),
  uploadFiles(Icons.upload_file_outlined, 'Upload File(s)', isSingle),
  uploadFolders(Icons.drive_folder_upload_outlined, 'Upload Folder(s)', isSingle),
  ;

  const MenuOption(this.icon, this.text, this.filter);

  final IconData icon;
  final String text;
  final FutureOr<bool> Function(PhylumAccount account, Iterable<Resource> resources) filter;
}

void handleOption(BuildContext context, Iterable<Resource> resources, MenuOption option) async {
  final account = context.read<PhylumAccount>();
  switch (option) {
    case MenuOption.rename:
      assert(resources.length == 1);
      final name = await showInputDialog(context, title: 'Rename', preset: resources.first.name);
      if (name != null) {
        account.addAction(ResourceMoveAction(r: resources.first, name: name));
      }
      break;
    case MenuOption.move:
      break;
    case MenuOption.copy:
      break;
    case MenuOption.delete:
      final name = resources.length == 1 ? resources.first.name : '${resources.length} items';
      final confirm = await showAlertDialog(context, title: 'Delete $name?', positiveText: 'YES', negativeText: 'NO') ?? false;
      if (confirm) {
        for (final r in resources) {
          account.addAction(ResourceDeleteAction(r: r));
        }
      }
      break;
    case MenuOption.details:
      showReponsiveDialog(context, 'Details', (context) => ResourceInfoView(resource: resources.first));
      break;
    case MenuOption.permissions:
    case MenuOption.publinks:
    case MenuOption.download:
      for (final r in resources) {
        context.read<DownloadManager>().downloadResource(r);
      }
      break;
    case MenuOption.bookmarkAdd:
      if (resources.length == 1) {
        final r = resources.first;
        final name = await showInputDialog(
          context,
          autocorrect: false,
          title: 'Add Bookmark',
          labelText: 'Name',
          preset: r.name,
        );
        if (name == null || !context.mounted) {
          return;
        }
        account.addAction(BookmarkAddAction(r: r, name: name.isEmpty ? '' : name));
      } else {
        for (final r in resources) {
          account.addAction(BookmarkAddAction(r: r));
        }
      }
      break;
    case MenuOption.bookmarkRemove:
      for (final r in resources) {
        account.addAction(BookmarkRemoveAction(r: r));
      }
      break;
    case MenuOption.newFolder:
      Actions.maybeInvoke(context, const NewFolderIntent());
    case MenuOption.uploadFiles:
      Actions.maybeInvoke(context, const UploadFilesIntent());
    case MenuOption.uploadFolders:
      Actions.maybeInvoke(context, const UploadFolderIntent());
  }
}

bool isSingle(PhylumAccount account, Iterable<Resource> resources) => resources.length == 1;

bool none(PhylumAccount account, Iterable<Resource> resources) => false;

bool all(PhylumAccount accout, Iterable<Resource> resources) => true;

bool isFilesOnly(PhylumAccount account, Iterable<Resource> resources) => resources.every((r) => !r.dir);

Future<bool> notAllBookmarked(PhylumAccount account, Iterable<Resource> resources) => allBookmarked(account, resources).then((b) => !b);

Future<bool> allBookmarked(PhylumAccount account, Iterable<Resource> resources) =>
    account.bookmarkRepository.bookmarksCount(resources.map((r) => r.id)).getSingle().then((c) => c == resources.length);
