import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_move.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/paste_action_handler.dart';
import 'package:phylum/ui/preview/resource_preview.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'explorer_view_controller.dart';

class ExplorerActions extends StatelessWidget {
  final Widget child;

  const ExplorerActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
        PasteFromClipboardIntent: CallbackAction<PasteFromClipboardIntent>(onInvoke: (PasteFromClipboardIntent i) => handlePasteAction(i, context)),
        SelectAllIntent: CallbackAction<SelectAllIntent>(onInvoke: (i) {
          context.read<ExplorerViewController>().selectAll(showFocus: true);
          return null;
        }),
        DismissIntent: CallbackAction<DismissIntent>(onInvoke: (i) {
          context.read<ExplorerViewController>().updateSelection((i) => i, SelectionMode.none, true);
          return null;
        }),
        ToggleSelectionIntent: CallbackAction<ToggleSelectionIntent>(onInvoke: (i) {
          context.read<ExplorerViewController>().updateSelection((i) => i, SelectionMode.toggle, true);
          return null;
        }),
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (i) {
          final r = context.read<ExplorerViewState>().selectedSingle;
          if (r == null) return;
          _openResource(context, r);
          return null;
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (i) {
          final selected = context.read<ExplorerViewState>().selected;
          _deleteResources(context, selected);
          return null;
        }),
        RenameIntent: CallbackAction<RenameIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final r = context.read<ExplorerViewState>().selectedSingle;
          if (r == null) return;
          final name = await showInputDialog(context, title: 'Rename', preset: r.name);
          if (name != null) {
            account.addAction(ResourceMoveAction(r: r, name: name));
          }
          return null;
        }),
        CopyToClipboardIntent: CallbackAction<CopyToClipboardIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final selected = context.read<ExplorerViewState>().selected;
          final items = selected.map((r) {
            final uri = account.apiClient.createUriBuilder('/open');
            uri.queryParameters['id'] = r.id;
            if (i.cut) {
              uri.queryParameters['cut'] = 'y';
            }
            final uriData = Formats.uri(NamedUri(uri.build(), name: r.name));
            return DataWriterItem(suggestedName: r.name)..add(uriData);
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${items.length} items ${i.cut ? 'cut' : 'copied'} to clipboard')));
          await SystemClipboard.instance?.write(items);
          return null;
        }),
      },
      child: child,
    );
  }

  void _openResource(BuildContext context, Resource r) {
    if (r.dir) {
      Actions.maybeInvoke(context, NavToFolderIntent(folderId: r.id));
    } else {
      ResourcePreview.showPreview(context, r.id);
    }
  }

  void _deleteResources(BuildContext context, Iterable<Resource> resources) async {
    final account = context.read<PhylumAccount>();
    // TOOD: #folderconfirmation
    final confirm =
        await showAlertDialog(context, title: 'Delete selected items?', barrierDismissible: true, positiveText: 'YES', negativeText: 'NO') ?? false;

    if (!confirm) return;
    for (final r in resources) {
      account.addAction(ResourceDeleteAction(r: r));
    }
  }
}
