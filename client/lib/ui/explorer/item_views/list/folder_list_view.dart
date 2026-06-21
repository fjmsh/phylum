import 'package:flutter/material.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/item_views/list/folder_list_item.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/resource_item_gesture_handler.dart';
import 'package:provider/provider.dart';

import '../../explorer_controller.dart';

class FolderListView extends StatefulWidget {
  const FolderListView({super.key});

  @override
  State<FolderListView> createState() => _FolderListViewState();
}

class _FolderListViewState extends State<FolderListView> {
  double? _rowHeight;
  double _viewportHeight = 0.0;
  final _scrollController = ScrollController(debugLabel: "FolderList");

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void ensureVisible(int index) {
    final currentOffset = _scrollController.offset;
    final itemStart = index * _rowHeight!;
    if (itemStart < currentOffset) {
      _scrollController.jumpTo(itemStart);
    } else if (currentOffset <= itemStart + _rowHeight! + -_viewportHeight) {
      _scrollController.jumpTo(itemStart - _viewportHeight + _rowHeight!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resources = context.select<ExplorerState, List<Resource>>(
      (state) => state.resources,
    );
    return Actions(
      actions: {
        FocusUpIntent: CallbackAction<FocusUpIntent>(
          onInvoke: (i) {
            final index = context.read<ExplorerController>().updateSelection(
              (i) => i - 1,
              i.mode,
              true,
            );
            ensureVisible(index);
            return null;
          },
        ),
        FocusDownIntent: CallbackAction<FocusDownIntent>(
          onInvoke: (i) {
            final index = context.read<ExplorerController>().updateSelection(
              (i) => i + 1,
              i.mode,
              true,
            );
            ensureVisible(index);
            return null;
          },
        ),
        FocusFirstIntent: CallbackAction<FocusFirstIntent>(
          onInvoke: (i) {
            final index = context.read<ExplorerController>().updateSelection(
              (i) => 0,
              i.mode,
              true,
            );
            ensureVisible(index);
            return null;
          },
        ),
        FocusLastIntent: CallbackAction<FocusLastIntent>(
          onInvoke: (i) {
            final index = context.read<ExplorerController>().updateSelection(
              (i) => 1 << 31,
              i.mode,
              true,
            );
            ensureVisible(index);
            return null;
          },
        ),
      },
      child: Focus(
        autofocus: true,
        descendantsAreFocusable: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _rowHeight ??= FolderListItem.calculateHeight(context);
            _viewportHeight = constraints.maxHeight;
            return ListView.builder(
              itemCount: resources.length,
              itemExtent: _rowHeight,
              controller: _scrollController,
              itemBuilder: (context, index) {
                final resource = resources[index];
                return (resource.dir)
                    ? ResourceDragTarget(
                        resourceId: resource.id,
                        buildItem: (context, dropTargetActive) =>
                            ResourceItemGestureHandler(
                              index: index,
                              resource: resource,
                              buildItem: () => FolderListItem(
                                resource: resource,
                                dropTargetActive: dropTargetActive,
                              ),
                            ),
                      )
                    : ResourceItemGestureHandler(
                        index: index,
                        resource: resource,
                        buildItem: () => FolderListItem(
                          resource: resource,
                          dropTargetActive: false,
                        ),
                      );
              },
            );
          },
        ),
      ),
    );
  }
}
