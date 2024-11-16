import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/resource_drop_target.dart';
import 'package:phylum/ui/explorer/resource_item_gesture_handler.dart';
import 'package:provider/provider.dart';

import 'explorer_actions.dart';
import 'explorer_view_controller.dart';

class FolderListView extends StatefulWidget {
  const FolderListView({super.key});

  @override
  State<FolderListView> createState() => _FolderListViewState();
}

class _FolderListViewState extends State<FolderListView> {
  @override
  Widget build(BuildContext context) {
    final resources = context.select<ExplorerViewState, List<Resource>>((state) => state.resources);
    return ExplorerActions(
      child: Focus(
        autofocus: true,
        descendantsAreFocusable: false,
        child: ListTileTheme(
          data: ListTileThemeData(
            mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.basic),
            selectedTileColor: Theme.of(context).colorScheme.primaryContainer,
          ),
          child: ListView.builder(
              itemCount: resources.length,
              itemBuilder: (context, index) => ResourceDropTarget(
                    resource: resources[index],
                    buildItem: (resource, dropTargetActive) => ResourceItemGestureHandler(
                      index: index,
                      resource: resources[index],
                      dropTargetActive: dropTargetActive,
                    ),
                  )),
        ),
      ),
    );
  }
}
