import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/paste_helpers.dart';
import 'package:phylum/ui/explorer/resource_details_row.dart';
import 'package:phylum/ui/explorer/resource_icon_extension.dart';
import 'package:phylum/ui/explorer/selection_mode.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:provider/provider.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

@pragma('vm:platform-const')
final bool _useSuperNative =
    defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS;

typedef DropWidgetBuilder = Widget Function(BuildContext context, bool dropTargetActive);

class ResourceDragTarget extends StatefulWidget {
  final String resourceId;

  final DropWidgetBuilder buildItem;

  ResourceDragTarget({required this.resourceId, required this.buildItem}) : super(key: ValueKey(resourceId));

  @override
  State<ResourceDragTarget> createState() => _ResourceDragTargetState();
}

class _ResourceDragTargetState extends State<ResourceDragTarget> {
  bool dropTargetActive = false;

  @override
  Widget build(BuildContext context) {
    return DragTarget(
      builder: (context, candidate, rejected) => widget.buildItem(context, dropTargetActive),
      onWillAcceptWithDetails: (details) {
        final state = context.read<ExplorerState>();
        if (state.selectedIds.contains(widget.resourceId) || state.folderId == widget.resourceId) {
          // Don't accept drops into selected resources or the parent
          return false;
        }
        setState(() => dropTargetActive = true);
        return true;
      },
      onLeave: (data) {
        setState(() => dropTargetActive = false);
      },
      onAcceptWithDetails: (details) async {
        final account = context.read<PhylumAccount>();
        final selected = context.read<ExplorerState>().selected;
        for (final r in selected) {
          handleNameConflict(
            context,
            r.name,
            overwriteFn: (r) => nameConflictDelete,
            (name, conflictResolution) => account.resourceRepository.move(
              resource: r,
              name: name,
              parent: widget.resourceId,
              conflictResolution: conflictResolution,
            ),
          );
        }
        setState(() => dropTargetActive = false);
      },
    );
  }
}

class ExternalDropRegion extends StatefulWidget {
  final DropWidgetBuilder buildItem;

  const ExternalDropRegion({super.key, required this.buildItem});

  @override
  State<ExternalDropRegion> createState() => _ExternalDropRegionState();
}

class _ExternalDropRegionState extends State<ExternalDropRegion> {
  bool dropTargetActive = false;

  @override
  Widget build(BuildContext context) {
    return _useSuperNative ? buildDropRegion(context) : widget.buildItem(context, false);
  }

  Widget buildDropRegion(BuildContext context) {
    return DropRegion(
      formats: Formats.standardFormats,
      child: widget.buildItem(context, dropTargetActive),
      onDropOver: (event) {
        if (event.session.items.isEmpty) return DropOperation.none;
        if (context.read<ExplorerState>().folderId == null) return DropOperation.none;
        for (final item in event.session.items) {
          if (kIsWeb || item.canProvide(Formats.fileUri)) {
            return DropOperation.copy;
          }
        }
        return DropOperation.none;
      },
      onDropEnter: (event) => setState(() => dropTargetActive = true),
      onDropLeave: (event) => setState(() => dropTargetActive = false),
      onPerformDrop: (event) async {
        final folderId = context.read<ExplorerState>().folderId;
        if (folderId == null) return;
        if (!mounted) return;
        processPasteItems(
          context,
          folderId,
          event.session.items.map((item) => item.dataReader).whereType(),
          copyMoveFn: context.read<PhylumAccount>().resourceRepository.copy,
        );

        setState(() => dropTargetActive = false);
      },
    );
  }
}

class ResourceDraggable extends StatelessWidget {
  final int index;
  final Resource resource;
  final bool dropTargetActive;

  const ResourceDraggable({super.key, required this.resource, required this.index, required this.dropTargetActive});

  @override
  Widget build(BuildContext context) {
    return _CustomDraggable(
      supportedDevices: {
        PointerDeviceKind.trackpad,
        PointerDeviceKind.mouse,
      },
      data: '__selected',
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () => _onDragStarted(context),
      onDragEnd: (details) {
        context.read<ExplorerController>().setDragging(false);
      },
      feedback: _feedback(context),
      child: _CustomDraggable(
          delay: const Duration(milliseconds: 500),
          supportedDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
            PointerDeviceKind.unknown,
          },
          hapticFeedbackOnStart: true,
          data: '__selected',
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: () => _onDragStarted(context),
          onDragEnd: (details) {
            context.read<ExplorerController>().setDragging(false);
          },
          feedback: _feedback(context),
          child: ResourceDetailsRow(
            resource: resource,
            dropTargetActive: dropTargetActive,
          )),
    );
  }

  void _onDragStarted(BuildContext context) {
    final controller = context.read<ExplorerController>();
    if (!context.read<ExplorerState>().isSelected(resource.id)) {
      controller.updateSelection((_) => index, SelectionMode.single, false);
    }
    controller.setDragging(true);
  }

  Widget _feedback(BuildContext context) {
    return Builder(
      builder: (ctx) {
        final theme = Theme.of(context);
        final count = context.read<ExplorerState>().selectedIds.length;
        return Card(
          shape: RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.primary), borderRadius: BorderRadius.circular(4.0)),
          elevation: 16.0,
          margin: const EdgeInsets.only(left: 16.0),
          child: SizedBox(
            width: 240,
            height: 48,
            child: ListTile(
              leading: resource.getIcon(),
              title: Text(
                resource.name,
                softWrap: false,
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
              trailing: count == 1 ? null : Badge(label: Text(count.toString(), style: const TextStyle(fontSize: 14))),
            ),
          ),
        );
      },
    );
  }
}

class _CustomDraggable<T extends Object> extends Draggable<T> {
  final Set<PointerDeviceKind>? supportedDevices;
  final Duration? delay;
  final bool hapticFeedbackOnStart;

  const _CustomDraggable({
    super.key,
    required super.child,
    required super.feedback,
    super.data,
    super.axis,
    super.childWhenDragging,
    super.feedbackOffset,
    super.dragAnchorStrategy,
    super.maxSimultaneousDrags,
    super.onDragStarted,
    super.onDragUpdate,
    super.onDraggableCanceled,
    super.onDragEnd,
    super.onDragCompleted,
    super.ignoringFeedbackSemantics,
    super.ignoringFeedbackPointer,
    super.allowedButtonsFilter,
    super.hitTestBehavior,
    super.rootOverlay,
    this.delay,
    this.hapticFeedbackOnStart = false,
    this.supportedDevices,
  });

  @override
  MultiDragGestureRecognizer createRecognizer(GestureMultiDragStartCallback onStart) {
    final recognizer = delay == null
        ? ImmediateMultiDragGestureRecognizer(
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter,
          )
        : DelayedMultiDragGestureRecognizer(
            delay: delay!,
            supportedDevices: supportedDevices,
            allowedButtonsFilter: allowedButtonsFilter,
          );
    return recognizer
      ..onStart = (Offset position) {
        final Drag? result = onStart(position);
        if (result != null && hapticFeedbackOnStart) {
          HapticFeedback.selectionClick();
        }
        return result;
      };
  }
}
