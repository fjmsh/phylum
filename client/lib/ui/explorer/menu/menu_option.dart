import 'dart:async';

import 'package:background_downloader/background_downloader.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:offtheline/offtheline.dart';
import 'package:open_file/open_file.dart';
import 'package:phylum/integrations/download_manager.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_restore.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/local_upload_errors.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/trash_empty_request.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/ui/common/responsive_dialog.dart';
import 'package:phylum/ui/destination_picker/destination_picker.dart';
import 'package:phylum/ui/explorer/details/resource_info_view.dart';
import 'package:phylum/ui/explorer/details/resource_permissions_view.dart';
import 'package:phylum/ui/explorer/details/resource_publinks_view.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';

import 'package:phylum/util/pick_directory_stub.dart'
    if (dart.library.js_interop) 'package:phylum/util/pick_directory_web.dart'
    if (dart.library.ffi) 'package:phylum/util/pick_directory_vm.dart';

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
  openWith(Icons.open_with, 'Open With', isSingle);

  const MenuOption(this.icon, this.text, this.filter);

  final IconData icon;
  final String text;
  final FutureOr<bool> Function(
    PhylumAccount account,
    Iterable<Resource> resources,
  )
  filter;
}

void handleOption(
  BuildContext context,
  Iterable<Resource> resources,
  MenuOption option,
) async {
  final account = context.read<PhylumAccount>();
  switch (option) {
    case MenuOption.rename:
      assert(resources.length == 1);
      final name = await showInputDialog(
        context,
        title: 'Rename',
        preset: resources.first.name,
      );
      if (name != null && context.mounted) {
        final r = resources.first;
        await handleLocalErrors(
          context,
          name,
          overwriteFn: (r) => nameConflictDelete,
          (name, conflictResolution, ensurePermission) =>
              account.resourceRepository.move(
                resource: r,
                name: name,
                parent: r.parent!,
                conflictResolution: conflictResolution,
                ensurePermission: ensurePermission,
              ),
        );
      }
      break;
    case MenuOption.move:
      final parent = resources.firstOrNull?.parent;
      if (parent == null) return;
      final dest = await DestinationPicker.show(
        context,
        initialFolderId: parent,
      );
      if (dest == null) {
        return;
      }
      if (!context.mounted) return;
      for (final r in resources) {
        await handleLocalErrors(
          context,
          r.name,
          overwriteFn: (r) => nameConflictDelete,
          (name, conflictResolution, ensurePermission) =>
              account.resourceRepository.move(
                resource: r,
                name: name,
                parent: dest,
                conflictResolution: conflictResolution,
                ensurePermission: ensurePermission,
              ),
        );
      }
      break;
    case MenuOption.copy:
      final parent = resources.firstOrNull?.parent;
      if (parent == null) return;
      final dest = await DestinationPicker.show(
        context,
        initialFolderId: parent,
        allowInitialFolder: true,
      );
      if (dest == null) {
        return;
      }
      if (!context.mounted) return;
      for (final r in resources) {
        await handleLocalErrors(
          context,
          r.name,
          overwriteFn: (r) => nameConflictDelete,
          (name, conflictResolution, ensurePermission) =>
              account.resourceRepository.copy(
                resource: r,
                name: name,
                parent: dest,
                conflictResolution: conflictResolution,
                ensurePermission: ensurePermission,
              ),
        );
      }
      break;
    case MenuOption.delete:
      final name = resources.length == 1
          ? resources.first.name
          : '${resources.length} items';
      final confirm =
          await showAlertDialog(
            context,
            title: 'Send $name to trash?',
            positiveText: 'YES',
            negativeText: 'NO',
          ) ??
          false;
      if (confirm) {
        for (final r in resources) {
          account.addAction(
            ResourceDeleteAction(r: r, timestamp: DateTime.now()),
          );
        }
      }
      break;
    case MenuOption.restore:
      for (final r in resources) {
        account.addAction(
          ResourceRestoreAction(r: r, timestamp: DateTime.now()),
        );
      }
      break;
    case MenuOption.deleteForever:
      final name = resources.length == 1
          ? resources.first.name
          : '${resources.length} items';
      final confirm =
          await showAlertDialog(
            context,
            title: 'Delete $name permanently?',
            positiveText: 'YES',
            negativeText: 'NO',
          ) ??
          false;
      if (confirm) {
        for (final r in resources) {
          account.addAction(
            ResourceDeleteAction(
              r: r,
              timestamp: DateTime.now(),
              permanent: true,
            ),
          );
        }
      }
      break;
    case MenuOption.emptyTrash:
      final confirm =
          await showAlertDialog(
            context,
            title: 'Empty Trash?',
            message: 'This will permanently delete all items in trash',
            positiveText: 'YES',
            negativeText: 'NO',
          ) ??
          false;
      if (confirm) {
        final response = await account.apiClient.sendRequest(
          TrashEmptyRequest(),
        );
        if (response is ApiSuccessResponse) {
          account.db.trashedResources.deleteAll();
        } else if (context.mounted) {
          showAlertDialog(
            context,
            title: 'Could not empty trash',
            message: response.description,
          );
        }
      }
    case MenuOption.details:
      final resource = resources.firstOrNull;
      if (resource == null) return;
      showReponsiveDialog(
        context,
        resource.name,
        (context) => ResourceInfoView(resource: resource),
      );
      break;
    case MenuOption.permissions:
      showReponsiveDialog(
        context,
        'Permissions for ${resources.first.name}',
        (context) => ResourcePermissionsView(resourceId: resources.first.id),
      );
    case MenuOption.publinks:
      final resource = resources.firstOrNull;
      if (resource == null) return;
      showReponsiveDialog(
        context,
        'Public Shares',
        (context) => ResourcePublinksView(resource: resource),
      );
      break;
    case MenuOption.download:
      for (final r in resources) {
        if (!r.dir) {
          downloadResource(context, r);
        }
      }
      break;

    case MenuOption.copyURL:
      final resource = resources.firstOrNull;
      if (resource == null) return;
      final url = account.apiClient.createUri(
        '/${resource.dir ? 'folder' : 'file'}/${resource.id}',
      );
      await Clipboard.setData(ClipboardData(text: url.toString()));
    case MenuOption.share:
      if (kIsWeb) return;
      final List<String> downloaded = [];
      for (final r in resources) {
        if (context.mounted) {
          final path = await downloadResourceSync(context, r);
          if (path != null) {
            downloaded.add(path);
          }
        }
      }
      if (downloaded.isEmpty) return;

      final params = ShareParams(
        files: downloaded.map((p) => XFile(p)).toList(growable: false),
        fileNameOverrides: downloaded
            .map((p) => path.basename(p))
            .toList(growable: false),
      );
      SharePlus.instance.share(params);
      break;
    case MenuOption.openWith:
      if (kIsWeb || resources.isEmpty) return;
      final r = resources.first;
      final p = await downloadResourceSync(context, r);
      if (p == null || !context.mounted) return;
      final version = await context
          .read<PhylumAccount>()
          .db
          .latestVersion(r.id)
          .getSingleOrNull();
      OpenFile.open(p, type: version?.mimeType);
      break;
    case MenuOption.bookmarkEdit:
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
        account.bookmarkRepository.addBookmark(resource: r, name: name);
      } else {
        for (final r in resources) {
          account.bookmarkRepository.addBookmark(resource: r);
        }
      }
      break;
    case MenuOption.bookmarkRemove:
      for (final r in resources) {
        account.bookmarkRepository.removeBookmark(resourceId: r.id);
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

Future<String?> downloadResourceSync(BuildContext context, Resource r) async {
  final account = context.read<PhylumAccount>();
  final uri = account.apiClient.createUriBuilder(
    '/api/v1/fs/contents/${r.id}:',
  );
  final task = DownloadTask(
    url: uri.toString(),
    headers: account.apiClient.requestHeaders,
    baseDirectory: BaseDirectory.temporary,
    filename: r.name,
    displayName: r.name,
    group: 'immediate',
    priority: 0,
    updates: Updates.progress,
  );
  final downloadStreamController = StreamController<double?>();
  bool dialogVisivle = true;
  showProgresIndicatorDialog(
    context,
    title: r.name,
    barrierDismissible: true,
    progress: downloadStreamController.stream,
  ).then((value) {
    dialogVisivle = false;
    if (value != true) {
      // Task cancelled
      FileDownloader().cancelTaskWithId(task.taskId);
    }
  });
  final status = await FileDownloader().download(
    task,
    onProgress: (progress) {
      downloadStreamController.add(progress);
    },
  );
  downloadStreamController.close();
  if (context.mounted && dialogVisivle) Navigator.of(context).pop(true);
  if (status.status == TaskStatus.complete) {
    final directory = await getTemporaryDirectory();
    return path.join(directory.path, task.filename);
  }
  return null;
}

bool isSingle(PhylumAccount account, Iterable<Resource> resources) =>
    resources.length == 1;

bool isSingleAndSupportsFolderUpload(
  PhylumAccount account,
  Iterable<Resource> resources,
) => resources.length == 1 && folderUploadSupported;

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
