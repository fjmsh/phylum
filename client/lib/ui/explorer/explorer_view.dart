import 'package:flutter/material.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:phylum/ui/explorer/paste_action_handler.dart';
import 'package:phylum/ui/explorer/resource_info_view.dart';
import 'package:provider/provider.dart';

import 'explorer_view_controller.dart';
import 'folder_empty_view.dart';
import 'folder_list_view.dart';

enum ExplorerLayout {
  noSidebar,
  smallSidebar,
  largeSidebar,
}

class ExplorerView extends StatelessWidget {
  const ExplorerView({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = context.watch<LayoutData>();
    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
        PasteFromClipboardIntent: CallbackAction<PasteFromClipboardIntent>(onInvoke: (PasteFromClipboardIntent i) => handlePasteAction(i, context)),
      },
      child: layout.type.isExpanded
          ? Row(
              children: [
                Expanded(child: Card(elevation: 0, child: buildPage(context))),
                SizedBox(
                  width: layout.type == LayoutType.expandedLarge ? 360 : 300,
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.only(left: 16),
                    child: ResourceInfoView(),
                  ),
                )
              ],
            )
          : buildPage(context),
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
