import 'package:flutter/material.dart';
import 'package:phylum/ui/app/clipboard.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/local_upload_errors.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/routes.dart';
import 'package:phylum/ui/explorer/paste_helpers.dart';
import 'package:phylum/ui/explorer/selection_mode.dart';
import 'package:phylum/ui/file_preview/file_preview_dialog.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'explorer_controller.dart';

class ExplorerActions extends StatelessWidget {
  final GlobalKey<RefreshIndicatorState> refreshKey;
  final Widget child;

  const ExplorerActions({super.key, required this.child, required this.refreshKey});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
        RefreshIntent: CallbackAction<RefreshIntent>(onInvoke: (i) => refreshKey.currentState?.show()),
        PasteFromClipboardIntent: CallbackAction<PasteFromClipboardIntent>(
          onInvoke: (PasteFromClipboardIntent i) async {
            final folderId = context.read<ExplorerState>().folderId;
            if (folderId == null) return;

            final clipboard = SystemClipboard.instance;
            if (clipboard == null) return;

            final reader = await clipboard.read();
            if (!context.mounted) return;
            processPasteItems(
              context,
              folderId,
              reader.items,
            );

            await SystemClipboard.instance?.write([]);
            return null;
          },
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
          if (r.dir) {
            Actions.maybeInvoke(context, NavIntent(target: ExplorerRouteFolder(folderId: r.id)));
          } else {
            final resources = state.resources.where((r) => !r.dir).toList(growable: false);
            final index = resources.indexOf(r);
            if (index >= 0) {
              FilePreviewDialog.showResources(context, resources, index);
            }
          }
          return;
        }),
        DeleteIntent: CallbackAction<DeleteIntent>(onInvoke: (i) {
          final selected = context.read<ExplorerState>().selected;
          final permanent = i.permanent || selected.every((r) => r.deleted != null);
          _deleteResources(context, selected, permanent);
          return null;
        }),
        RenameIntent: CallbackAction<RenameIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final r = context.read<ExplorerState>().selectedSingle;
          if (r == null) return;
          final name = await showInputDialog(context, title: 'Rename', preset: r.name);
          if (name != null && context.mounted) {
            handleLocalErrors(
              context,
              name,
              overwriteFn: (r) => nameConflictDelete,
              (name, conflictResolution, ensurePermission) => account.resourceRepository.move(
                resource: r,
                name: name,
                parent: r.parent!,
                conflictResolution: conflictResolution,
                ensurePermission: ensurePermission,
              ),
            );
          }
          return null;
        }),
        CopyToClipboardIntent: CallbackAction<CopyToClipboardIntent>(onInvoke: (i) async {
          final account = context.read<PhylumAccount>();
          final selected = context.read<ExplorerState>().selected;
          if (selected.isEmpty) return;
          final items = selected.map((r) {
            final uri = account.apiClient.createUriBuilder(r.dir ? '/folder/${r.id}' : '/file/${r.id}');
            final uriData = Formats.uri(NamedUri(uri.build(), name: r.name));
            return DataWriterItem(suggestedName: r.name)..add(uriData);
          });

          context.read<CutToClipboard>().ids = i.cut ? selected.map((r) => r.id).toList(growable: false) : const [];

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('${items.length} items ${i.cut ? 'cut' : 'copied'} to clipboard')));
          await SystemClipboard.instance?.write(items);
          return null;
        }),
      },
      child: child,
    );
  }

  void _deleteResources(BuildContext context, Iterable<Resource> resources, bool permanent) async {
    final account = context.read<PhylumAccount>();
    final confirm = await showAlertDialog(
          context,
          title: permanent ? 'Permanently delete selected items?' : 'Delete selected items?',
          barrierDismissible: true,
          positiveText: 'YES',
          negativeText: 'NO',
        ) ??
        false;

    if (!confirm) return;
    for (final r in resources) {
      account.addAction(ResourceDeleteAction(r: r, timestamp: DateTime.now(), permanent: permanent));
    }
  }
}
