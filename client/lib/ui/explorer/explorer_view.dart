import 'package:flutter/material.dart';
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
  const ExplorerView._({super.key});

  static Widget create(String folderId, ExplorerLayout layout) {
    final explorer = PasteActionHandler(folderId: folderId, child: ExplorerView._(key: ValueKey(folderId)));
    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
      },
      child: layout == ExplorerLayout.noSidebar
          ? explorer
          : Row(
              children: [
                Expanded(child: Card(elevation: 0, child: explorer)),
                SizedBox(
                  width: layout == ExplorerLayout.largeSidebar ? 360 : 300,
                  child: Card(
                    elevation: 0,
                    margin: EdgeInsets.only(left: 16),
                    child: ResourceInfoView(),
                  ),
                )
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
