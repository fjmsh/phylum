import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/phylum_account.dart';
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
    return StateNotifierProvider<ExplorerViewController, ExplorerViewState>(
      create: (context) => ExplorerViewController(account: context.read<PhylumAccount>(), folderId: folderId),
      child: Actions(
        actions: {
          NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
          PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
        },
        child: layout == ExplorerLayout.noSidebar
            ? explorer
            : Row(
                children: [
                  Expanded(child: Card(child: explorer)),
                  SizedBox(
                    width: layout == ExplorerLayout.largeSidebar ? 360 : 300,
                    child: Card(
                      margin: EdgeInsets.only(left: 16, bottom: 16),
                      child: ResourceInfoView(folderId: folderId),
                    ),
                  )
                ],
              ),
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
