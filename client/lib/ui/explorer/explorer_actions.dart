import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/paste_action_handler.dart';
import 'package:phylum/libphylum/explorer/selection_mode.dart';
import 'package:phylum/ui/preview/resource_preview.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

import '../../libphylum/explorer/explorer_controller.dart';

class ExplorerActions extends StatelessWidget {
  final Widget child;

  const ExplorerActions({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(
          onInvoke: (i) => null,
        ),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(
          onInvoke: (i) => null,
        ),
        PasteFromClipboardIntent: CallbackAction<PasteFromClipboardIntent>(
          onInvoke: (PasteFromClipboardIntent i) => handlePasteAction(i, context),
        ),
        SelectAllIntent: CallbackAction<SelectAllIntent>(
          onInvoke: (i) => context.read<ExplorerController>().updateSelection((i) => i, SelectionMode.all, true),
        ),
        DismissIntent: CallbackAction<DismissIntent>(
          onInvoke: (i) => context.read<ExplorerController>().updateSelection((i) => i, SelectionMode.none, true),
        ),
        ToggleSelectionIntent: CallbackAction<ToggleSelectionIntent>(
          onInvoke: (i) => context.read<ExplorerController>().updateSelection((i) => i, SelectionMode.toggle, true),
        ),
        ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (i) {
          final state = context.read<ExplorerState>();
          final r = state.selectedSingle ?? state.focussed;
          if (r == null) return;
          _openResource(context, r);
          return;
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (i) {
          final selected = context.read<ExplorerState>().selected;
          _deleteResources(context, selected);
          return null;
        }),
        RenameIntent: CallbackAction<RenameIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final r = context.read<ExplorerState>().selectedSingle;
          if (r == null) return;
          final name = await showInputDialog(context, title: 'Rename', preset: r.name);
          if (name != null && context.mounted) {
            handleNameConflict(
              context,
              name,
              overwriteFn: (r) => nameConflictDelete,
              (name, conflictResolution) => account.resourceRepository.move(
                resource: r,
                name: name,
                parent: r.parent!,
                conflictResolution: conflictResolution,
              ),
            );
          }
          return null;
        }),
        CopyToClipboardIntent: CallbackAction<CopyToClipboardIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final selected = context.read<ExplorerState>().selected;
          final items = selected.map((r) {
            final uri = account.apiClient.createUriBuilder('/open');
            uri.queryParameters['id'] = r.id;
            if (i.cut) {
              uri.queryParameters['cut'] = 'y';
            }
            final uriData = Formats.uri(NamedUri(uri.build(), name: r.name));
            return DataWriterItem(suggestedName: r.name)..add(uriData);
          });
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${items.length} items ${i.cut ? 'cut' : 'copied'} to clipboard')));
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
      ResourcePreview.showPreview(context, r);
    }
  }

  void _deleteResources(BuildContext context, Iterable<Resource> resources) async {
    final account = context.read<PhylumAccount>();
    final confirm = await showAlertDialog(
          context,
          title: 'Delete selected items?',
          barrierDismissible: true,
          positiveText: 'YES',
          negativeText: 'NO',
        ) ??
        false;

    if (!confirm) return;
    for (final r in resources) {
      account.addAction(ResourceDeleteAction(r: r));
    }
  }
}
