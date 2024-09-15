import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';

import 'explorer_view_controller.dart';
import 'folder_empty_view.dart';
import 'folder_list_view.dart';

class ExplorerView extends StatelessWidget {
  const ExplorerView._({super.key});

  static Widget create(String folderId) {
    return Builder(builder: (context) {
      return ListTileTheme(
        data: ListTileThemeData(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.basic),
          selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: StateNotifierProvider<ExplorerViewController, ExplorerViewState>(
          create: (context) => ExplorerViewController(account: context.read<PhylumAccount>(), folderId: folderId),
          child: Actions(
            actions: {
              NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
              PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
            },
            child: ExplorerView._(key: ValueKey(folderId)),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = context.select<ExplorerViewState, FolderEmptyViewType?>((state) {
      if (state.resources.isEmpty) {
        if (state.folder?.lastFetch == null) {
          return FolderEmptyViewType.loading;
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
