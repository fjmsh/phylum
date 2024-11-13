import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/explorer/paste_action_handler.dart';
import 'package:provider/provider.dart';

import 'explorer_view_controller.dart';
import 'folder_empty_view.dart';
import 'folder_list_view.dart';

class ExplorerView extends StatelessWidget {
  const ExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
        PasteFromClipboardIntent: CallbackAction<PasteFromClipboardIntent>(onInvoke: (PasteFromClipboardIntent i) => handlePasteAction(i, context)),
      },
      child: buildPage(context),
    );
  }

  Widget buildPage(BuildContext context) {
    final type = context.select<ExplorerViewState, FolderEmptyViewType?>((state) {
      if (state.resources.isEmpty) {
        if (state.refreshing) {
          return FolderEmptyViewType.loading;
        }
        if (state.refreshError) {
          return FolderEmptyViewType.error;
        }
        return FolderEmptyViewType.noData;
      }
      return null;
    });
    if (type != null) {
      return FolderEmptyView(
        type: type,
        onRefresh: context.read<ExplorerViewController>().refresh,
      );
    }
    return RefreshIndicator(
      onRefresh: context.read<ExplorerViewController>().refresh,
      child: const FolderListView(),
    );
  }
}
