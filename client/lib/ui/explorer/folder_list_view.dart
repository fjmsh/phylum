import 'package:flutter/material.dart';
import 'package:phylum/ui/app/shortcuts.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/resource_details_row.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/resource_item_gesture_handler.dart';
import 'package:provider/provider.dart';

import 'explorer_controller.dart';

class FolderListView extends StatefulWidget {
  const FolderListView({super.key});

  @override
  State<FolderListView> createState() => _FolderListViewState();
}

class _FolderListViewState extends State<FolderListView> {
  @override
  Widget build(BuildContext context) {
    final resources = context.select<ExplorerState, List<Resource>>((state) => state.resources);
    return Actions(
      actions: {
        FocusUpIntent: CallbackAction<FocusUpIntent>(onInvoke: (i) {
          context.read<ExplorerController>().updateSelection((i) => i - 1, i.mode, true);
          return null;
        }),
        FocusDownIntent: CallbackAction<FocusDownIntent>(onInvoke: (i) {
          context.read<ExplorerController>().updateSelection((i) => i + 1, i.mode, true);
          return null;
        }),
        FocusFirstIntent: CallbackAction<FocusFirstIntent>(onInvoke: (i) {
          context.read<ExplorerController>().updateSelection((i) => 0, i.mode, true);
          return null;
        }),
        FocusLastIntent: CallbackAction<FocusLastIntent>(onInvoke: (i) {
          context.read<ExplorerController>().updateSelection((i) => 4294967296, i.mode, true);
          return null;
        }),
      },
      child: Focus(
        autofocus: true,
        descendantsAreFocusable: false,
        child: ListView.builder(
            itemCount: resources.length,
            itemExtent: calculateRowHeight(context),
            itemBuilder: (context, index) {
              final resource = resources[index];
              return (resource.dir)
                  ? ResourceDragTarget(
                      resourceId: resource.id,
                      buildItem: (context, dropTargetActive) => ResourceItemGestureHandler(
                        index: index,
                        resource: resource,
                        dropTargetActive: dropTargetActive,
                      ),
                    )
                  : ResourceItemGestureHandler(
                      index: index,
                      resource: resource,
                      dropTargetActive: false,
                    );
            }),
      ),
    );
  }
}
