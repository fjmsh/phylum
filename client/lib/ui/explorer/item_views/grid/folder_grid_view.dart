import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/item_views/grid/folder_grid_item.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/resource_item_gesture_handler.dart';
import 'package:provider/provider.dart';

import '../../explorer_controller.dart';

const _rowSpacing = 12.0;

class FolderGridView extends StatefulWidget {
  final int itemWidth;

  const FolderGridView({super.key, required this.itemWidth});

  @override
  State<FolderGridView> createState() => _FolderGridViewState();
}

class _FolderGridViewState extends State<FolderGridView> {
  double _rowHeight = 0.0;
  double _viewportHeight = 0.0;
  int _crossAxisCount = 1;
  final _scrollController = ScrollController(debugLabel: "ResourceItemGrid");

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
    final itemStart = (index ~/ _crossAxisCount) * (_rowHeight + _rowSpacing);
    if (itemStart < currentOffset) {
      _scrollController.jumpTo(itemStart);
    } else if (currentOffset <= itemStart + _rowHeight + -_viewportHeight) {
      _scrollController.jumpTo(itemStart - _viewportHeight + _rowHeight);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resources = context.select<ExplorerState, List<Resource>>(
      (state) => state.resources,
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          _viewportHeight = constraints.maxHeight;
          final idealCount = constraints.maxWidth / widget.itemWidth;
          _crossAxisCount = idealCount.toInt();
          if (idealCount - _crossAxisCount > 0.75) {
            _crossAxisCount++;
          }
          _rowHeight = constraints.maxWidth / _crossAxisCount;
          return Actions(
            actions: {
              FocusUpIntent: CallbackAction<FocusUpIntent>(
                onInvoke: (i) {
                  final index = context
                      .read<ExplorerController>()
                      .updateSelection(
                        (i) => i < _crossAxisCount ? i : i - _crossAxisCount,
                        i.mode,
                        true,
                      );
                  ensureVisible(index);
                  return null;
                },
              ),
              FocusDownIntent: CallbackAction<FocusDownIntent>(
                onInvoke: (i) {
                  final index = context
                      .read<ExplorerController>()
                      .updateSelection(
                        (i) => i < 0
                            ? 0
                            : i + _crossAxisCount >= resources.length
                            ? i
                            : i + _crossAxisCount,
                        i.mode,
                        true,
                      );
                  ensureVisible(index);
                  return null;
                },
              ),
              FocusLeftIntent: CallbackAction<FocusLeftIntent>(
                onInvoke: (i) {
                  final index = context
                      .read<ExplorerController>()
                      .updateSelection((i) => i - 1, i.mode, true);
                  ensureVisible(index);
                  return null;
                },
              ),
              FocusRightIntent: CallbackAction<FocusRightIntent>(
                onInvoke: (i) {
                  final index = context
                      .read<ExplorerController>()
                      .updateSelection((i) => i + 1, i.mode, true);
                  ensureVisible(index);
                  return null;
                },
              ),
              FocusFirstIntent: CallbackAction<FocusFirstIntent>(
                onInvoke: (i) {
                  final index = context
                      .read<ExplorerController>()
                      .updateSelection((i) => 0, i.mode, true);
                  ensureVisible(index);
                  return null;
                },
              ),
              FocusLastIntent: CallbackAction<FocusLastIntent>(
                onInvoke: (i) {
                  final index = context
                      .read<ExplorerController>()
                      .updateSelection((i) => 1 << 31, i.mode, true);
                  ensureVisible(index);
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              descendantsAreFocusable: false,
              child: GridView.builder(
                itemCount: resources.length,
                controller: _scrollController,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: _rowSpacing,
                  mainAxisExtent: _rowHeight,
                ),
                itemBuilder: (context, index) {
                  final resource = resources[index];
                  return (resource.dir)
                      ? ResourceDragTarget(
                          resourceId: resource.id,
                          buildItem: (context, dropTargetActive) =>
                              ResourceItemGestureHandler(
                                index: index,
                                resource: resource,
                                buildItem: () => FolderGridItem(
                                  resource: resource,
                                  dropTargetActive: dropTargetActive,
                                ),
                              ),
                        )
                      : ResourceItemGestureHandler(
                          index: index,
                          resource: resource,
                          buildItem: () => FolderGridItem(
                            resource: resource,
                            dropTargetActive: false,
                          ),
                        );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
