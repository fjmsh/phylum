import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/layout/app_shortcuts.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/layout/search.dart';
import 'package:phylum/ui/explorer/page.dart';
import 'package:phylum/ui/preview/resource_preview.dart';
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
          onInvoke: (intent) async {
            final page = context.read<PhylumRouterDelegate>().currentConfiguration;
            final account = context.read<PhylumAccount>();
            final folderId = page?.folderId(account);
            if (folderId == null) return;
            final folder = await account.db.getResource(folderId);
            if (folder == null || !context.mounted) return;
            createDirectory(context, folder);
            return null;
          },
        ),
        UploadFilesIntent: CallbackAction<UploadFilesIntent>(
          onInvoke: (intent) {
            final page = context.read<PhylumRouterDelegate>().currentConfiguration;
            final account = context.read<PhylumAccount>();
            final folderId = page?.folderId(account);
            if (folderId != null) {
              pickAndUploadFiles(context, folderId);
            }
            return null;
          },
        ),
        UploadFolderIntent: CallbackAction<UploadFolderIntent>(
          onInvoke: (intent) {
            final page = context.read<PhylumRouterDelegate>().currentConfiguration;
            final account = context.read<PhylumAccount>();
            final folderId = page?.folderId(account);
            if (folderId != null) {
              pickAndUploadDirectory(context, folderId);
            }
            return null;
          },
        ),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
          final routerDelegate = context.read<PhylumRouterDelegate>();
          final page = routerDelegate.currentConfiguration;
          final account = context.read<PhylumAccount>();
          final folderId = page?.folderId(account);
          final parent = folderId == null ? null : (await account.db.getResource(folderId))?.parent;
          if (parent != null) {
            routerDelegate.go(ExplorerPageFolder(folderId: parent));
          }
          return null;
        }),
        NavIntent: CallbackAction<NavIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().go(i.target),
        ),
        NavHomeIntent: CallbackAction<NavHomeIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().go(ExplorerPageHome()),
        ),
        NavBackIntent: CallbackAction<NavBackIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().goBack(),
        ),
        NavForwardIntent: CallbackAction<NavForwardIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().goForward(),
        ),
        FocusSearchIntent: CallbackAction<FocusSearchIntent>(
          onInvoke: (i) => context.read<PhylumSearchController>().active = true,
        ),
        OpenResourceIntent: CallbackAction<OpenResourceIntent>(onInvoke: (i) async {
          final resource = i.resource;
          if (resource.dir) {
            context.read<PhylumRouterDelegate>().go(ExplorerPageFolder(folderId: resource.id));
            return null;
          }
          ResourcePreview.showPreview(context, [resource], 0);
          return null;
        })
      },
      child: child,
    );
  }
}
