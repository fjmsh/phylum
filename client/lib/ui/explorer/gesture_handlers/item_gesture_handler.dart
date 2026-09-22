import 'package:flutter/widgets.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/gesture_handlers/drag_handler.dart';

import 'item_mouse_gesture_handler.dart';
import 'item_touch_gesture_handler.dart';

class ResourceItemGestureHandler extends StatelessWidget {
  final int index;
  final Resource resource;
  final Widget Function() buildItem;

  const ResourceItemGestureHandler({
    super.key,
    required this.index,
    required this.resource,
    required this.buildItem,
  });

  @override
  Widget build(BuildContext context) {
    return ItemTouchGestureHandler(
      resourceId: resource.id,
      resourceIndex: index,
      child: ItemMouseGestureHandler(
        resourceId: resource.id,
        resourceIndex: index,
        child: DragHandler(
          resource: resource,
          index: index,
          buildItem: buildItem,
        ),
      ),
    );
  }
}
