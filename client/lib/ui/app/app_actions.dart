import 'package:flutter/material.dart';
import 'package:phylum/ui/app/app_shortcuts.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/libphylum/explorer/explorer_controller.dart';
import 'package:phylum/libphylum/explorer/page.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

class AppActions extends StatelessWidget {
  final Widget child;
  const AppActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NewFolderIntent: CallbackAction<NewFolderIntent>(
          onInvoke: (intent) {
            final folderId = context.read<ExplorerState>().folderId;
            if (folderId != null) {
              createDirectory(context, folderId);
            }
            return null;
          },
        ),
        UploadFilesIntent: CallbackAction<UploadFilesIntent>(
          onInvoke: (intent) {
            final folderId = context.read<ExplorerState>().folderId;
            if (folderId != null) {
              pickAndUploadFiles(context, folderId);
            }
            return null;
          },
        ),
        UploadFolderIntent: CallbackAction<UploadFolderIntent>(
          onInvoke: (intent) {
            final folderId = context.read<ExplorerState>().folderId;
            if (folderId != null) {
              pickAndUploadDirectory(context, folderId);
            }
            return null;
          },
        ),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
          final parent = context.read<ExplorerState>().folder?.parent;
          if (parent != null) {
            context.read<PhylumRouterDelegate>().go(ExplorerPageFolder(folderId: parent));
          }
          return null;
        }),
        NavHomeIntent: CallbackAction<NavHomeIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().go(const ExplorerPageHome()),
        ),
        NavToFolderIntent: CallbackAction<NavToFolderIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().go(ExplorerPageFolder(folderId: i.folderId)),
        ),
        NavBackIntent: CallbackAction<NavBackIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().goBack(),
        ),
        NavForwardIntent: CallbackAction<NavForwardIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().goForward(),
        ),
      },
      child: child,
    );
  }
}
