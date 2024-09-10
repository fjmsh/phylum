import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';

class AppActions extends StatelessWidget {
  final Widget child;
  const AppActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NewFolderIntent: CallbackAction<NewFolderIntent>(onInvoke: (intent) {
          final folderId = context.read<CurrentLocation>().folderId;
          return createDirectory(context, folderId);
        }),
        UploadFilesIntent: CallbackAction<UploadFilesIntent>(onInvoke: (intent) {
          final folderId = context.read<CurrentLocation>().folderId;
          return pickAndUploadFiles(context, folderId);
        }),
        UploadFolderIntent: CallbackAction<UploadFolderIntent>(onInvoke: (intent) {
          final folderId = context.read<CurrentLocation>().folderId;
          return pickAndUploadDirectory(context, folderId);
        }),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
          final folderId = context.read<CurrentLocation>().folderId;
          final r = await context.read<PhylumAccount>().resourceRepository.getResource(folderId);
          final parent = r?.parent;
          if (parent != null && context.mounted) {
            context.goNamed('folder', pathParameters: {'id': parent});
          }
          return null;
        }),
        NavBackIntent: CallbackAction<NavBackIntent>(onInvoke: (i) {
          if (context.canPop()) {
            context.pop();
          }
          return null;
        }),
        NavForwardIntent: CallbackAction<NavForwardIntent>(onInvoke: (i) {
          // context.read<NavHistoryManager>().goForward();
          return null;
        }),
      },
      child: child,
    );
  }
}
