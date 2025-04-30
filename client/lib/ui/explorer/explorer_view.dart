import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/explorer_actions.dart';
import 'package:phylum/ui/explorer/explorer_gesture_handler.dart';
import 'package:phylum/ui/explorer/path_view.dart';
import 'package:provider/provider.dart';

import 'explorer_controller.dart';
import 'folder_empty_view.dart';
import 'folder_list_view.dart';

class ExplorerView extends StatefulWidget {
  final bool small;

  const ExplorerView({super.key, required this.small});

  @override
  State<ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends State<ExplorerView> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  @override
  Widget build(BuildContext context) {
    return ExplorerActions(
      refreshKey: _refreshKey,
      child: ExplorerGestureHandler(
        child: Column(
          children: [
            PathView(small: widget.small),
            Expanded(child: buildPage(context)),
          ],
        ),
      ),
    );
  }

  Widget buildPage(BuildContext context) {
    final type = context.select<ExplorerState, FolderEmptyViewType?>((state) {
      if (state.resources.isEmpty) {
        if (state.refresh != null) {
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
        refreshKey: _refreshKey,
        onRefresh: context.read<ExplorerController>().refresh,
      );
    }
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: context.read<ExplorerController>().refresh,
      child: const FolderListView(),
    );
  }
}
