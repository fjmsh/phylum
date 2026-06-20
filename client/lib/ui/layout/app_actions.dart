import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routing/explorer_history_controller.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/ui/layout/search.dart';
import 'package:phylum/ui/file_viewer/file_viewer_dialog.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

import 'package:phylum/util/pick_directory_stub.dart'
    if (dart.library.js_interop) 'package:phylum/util/pick_directory_web.dart'
    if (dart.library.ffi) 'package:phylum/util/pick_directory_vm.dart';

class AppActions extends StatelessWidget {
  final Widget child;

  const AppActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NewFolderIntent: CallbackAction<NewFolderIntent>(
          onInvoke: (intent) async {
            final account = context.read<PhylumAccount>();
            final folderId = context
                .read<ExplorerHistoryController>()
                .currentLocation
                .folderId(context.read());
            if (folderId == null) return;
            final folder = await account.db.getResource(folderId);
            if (folder == null || !context.mounted) return;
            createDirectory(context, folder);
            return null;
          },
        ),
        UploadFilesIntent: CallbackAction<UploadFilesIntent>(
          onInvoke: (intent) {
            final folderId = context
                .read<ExplorerHistoryController>()
                .currentLocation
                .folderId(context.read());
            if (folderId != null) {
              pickAndUploadFiles(context, folderId);
            }
            return null;
          },
        ),
        UploadFolderIntent: CallbackAction<UploadFolderIntent>(
          onInvoke: (intent) {
            final folderId = context
                .read<ExplorerHistoryController>()
                .currentLocation
                .folderId(context.read());
            if (folderId != null) {
              pickAndUploadDirectory(context, folderId);
            }
            return null;
          },
        ),
        NavUpIntent: CallbackAction<NavUpIntent>(
          onInvoke: (i) async {
            final historyController = context.read<ExplorerHistoryController>();
            final account = context.read<PhylumAccount>();
            final folderId = historyController.currentLocation.folderId(
              account,
            );
            final parent = folderId == null
                ? null
                : (await account.db.getResource(folderId))?.parent;
            if (parent != null) {
              historyController.go(ExplorerLocationFolder(folderId: parent));
            }
            return null;
          },
        ),
        NavIntent: CallbackAction<NavIntent>(
          onInvoke: (i) =>
              context.read<ExplorerHistoryController>().go(i.target),
        ),
        NavHomeIntent: CallbackAction<NavHomeIntent>(
          onInvoke: (i) => context.read<ExplorerHistoryController>().go(
            ExplorerLocationHome(),
          ),
        ),
        NavBackIntent: CallbackAction<NavBackIntent>(
          onInvoke: (i) => context.read<ExplorerHistoryController>().goBack(),
        ),
        NavForwardIntent: CallbackAction<NavForwardIntent>(
          onInvoke: (i) =>
              context.read<ExplorerHistoryController>().goForward(),
        ),
        FocusSearchIntent: CallbackAction<FocusSearchIntent>(
          onInvoke: (i) => context.read<PhylumSearchController>().active = true,
        ),
        OpenResourceIntent: CallbackAction<OpenResourceIntent>(
          onInvoke: (i) async {
            final resource = i.resource;
            if (resource.dir) {
              context.read<ExplorerHistoryController>().go(
                ExplorerLocationFolder(folderId: resource.id),
              );
              return null;
            }
            FilePreviewDialog.showResources(context, [resource], 0);
            return null;
          },
        ),
      },
      child: child,
    );
  }
}
