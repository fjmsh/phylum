import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_shortcuts.dart';
import 'package:phylum/ui/app/router.dart';
import 'package:phylum/ui/app/search.dart';
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
          onInvoke: (intent) {
            final page = context.read<PhylumRouterDelegate>().currentConfiguration;
            final folderId = page is ExplorerPageFolder ? page.folderId : null;
            if (folderId != null) {
              createDirectory(context, folderId);
            }
            return null;
          },
        ),
        UploadFilesIntent: CallbackAction<UploadFilesIntent>(
          onInvoke: (intent) {
            final page = context.read<PhylumRouterDelegate>().currentConfiguration;
            final folderId = page is ExplorerPageFolder ? page.folderId : null;
            if (folderId != null) {
              pickAndUploadFiles(context, folderId);
            }
            return null;
          },
        ),
        UploadFolderIntent: CallbackAction<UploadFolderIntent>(
          onInvoke: (intent) {
            final page = context.read<PhylumRouterDelegate>().currentConfiguration;
            final folderId = page is ExplorerPageFolder ? page.folderId : null;
            if (folderId != null) {
              pickAndUploadDirectory(context, folderId);
            }
            return null;
          },
        ),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) async {
          final routerDelegate = context.read<PhylumRouterDelegate>();
          final page = routerDelegate.currentConfiguration;
          final folderId = page is ExplorerPageFolder ? page.folderId : null;
          if (folderId == null) return;
          final folder = await context.read<PhylumAccount>().db.getResource(folderId);
          if (folder?.parent != null) {
            routerDelegate.go(ExplorerPageFolder(folderId: folder!.parent!));
          }
          return null;
        }),
        NavIntent: CallbackAction<NavIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().go(i.target),
        ),
        NavHomeIntent: CallbackAction<NavHomeIntent>(
          onInvoke: (i) => context.read<PhylumRouterDelegate>().go(ExplorerPageHome(context.read())),
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
