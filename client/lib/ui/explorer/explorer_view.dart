import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/explorer_actions.dart';
import 'package:phylum/ui/explorer/explorer_gesture_handler.dart';
import 'package:phylum/ui/explorer/path_view.dart';
import 'package:provider/provider.dart';

import 'explorer_controller.dart';
import 'folder_empty_view.dart';
import 'folder_list_view.dart';

class ExplorerView extends StatelessWidget {
  final bool small;

  const ExplorerView({super.key, required this.small});

  @override
  Widget build(BuildContext context) {
    return ExplorerActions(
      child: ExplorerGestureHandler(
        child: Column(
          children: [
            PathView(small: small),
            Expanded(child: buildPage(context)),
          ],
        ),
      ),
    );
  }

  Widget buildPage(BuildContext context) {
    final type = context.select<ExplorerState, FolderEmptyViewType?>((state) {
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
        onRefresh: context.read<ExplorerController>().refresh,
      );
    }
    return RefreshIndicator(
      onRefresh: context.read<ExplorerController>().refresh,
      child: const FolderListView(),
    );
  }
}
