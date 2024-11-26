import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/navigation/destination.dart';
import 'package:phylum/ui/navigation/history_manager.dart';
import 'package:phylum/ui/navigation/explorer_controller.dart';
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
          onInvoke: (intent) => createDirectory(context, context.read<ExplorerState>().folderId),
        ),
        UploadFilesIntent: CallbackAction<UploadFilesIntent>(
          onInvoke: (intent) => pickAndUploadFiles(context, context.read<ExplorerState>().folderId),
        ),
        UploadFolderIntent: CallbackAction<UploadFolderIntent>(
          onInvoke: (intent) => pickAndUploadDirectory(context, context.read<ExplorerState>().folderId),
        ),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
          final parent = context.read<ExplorerState>().folder?.parent;
          if (parent != null) {
            context.read<NavHistoryManager>().go(context, NavDestinationFolder(folderId: parent));
          }
          return null;
        }),
        NavHomeIntent: CallbackAction<NavHomeIntent>(
          onInvoke: (i) => context.read<NavHistoryManager>().go(context, const NavDestinationHome()),
        ),
        NavToFolderIntent: CallbackAction<NavToFolderIntent>(
          onInvoke: (i) => context.read<NavHistoryManager>().go(context, NavDestinationFolder(folderId: i.folderId)),
        ),
        NavBackIntent: CallbackAction<NavBackIntent>(
          onInvoke: (i) => context.read<NavHistoryManager>().goBack(context),
        ),
        NavForwardIntent: CallbackAction<NavForwardIntent>(
          onInvoke: (i) => context.read<NavHistoryManager>().goForward(context),
        ),
      },
      child: child,
    );
  }
}
