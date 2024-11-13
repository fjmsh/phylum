import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/app/nav_history.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
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
          onInvoke: (intent) => createDirectory(context, context.read<ExplorerViewController>().folderId),
        ),
        UploadFilesIntent: CallbackAction<UploadFilesIntent>(
          onInvoke: (intent) => pickAndUploadFiles(context, context.read<ExplorerViewController>().folderId),
        ),
        UploadFolderIntent: CallbackAction<UploadFolderIntent>(
          onInvoke: (intent) => pickAndUploadDirectory(context, context.read<ExplorerViewController>().folderId),
        ),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
          final parent = context.read<ExplorerViewState>().folder?.parent;
          if (parent != null) {
            context.goNamed('folder', pathParameters: {'id': parent});
          }
          return null;
        }),
        NavBackIntent: CallbackAction<NavBackIntent>(
          onInvoke: (i) => context.read<NavHistoryManager>().goBack(context),
        ),
        NavForwardIntent: CallbackAction<NavForwardIntent>(
          onInvoke: (i) => context.read<NavHistoryManager>().goForward(context),
        ),
        NavHomeIntent: CallbackAction<NavHomeIntent>(
          onInvoke: (i) => context.goNamed('home'),
        ),
      },
      child: child,
    );
  }
}
