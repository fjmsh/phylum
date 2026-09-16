import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/resource_drop_and_drop.dart';
import 'package:phylum/ui/explorer/menu/menu_option.dart';
import 'package:phylum/ui/explorer/menu/option_groups.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';
import 'package:provider/provider.dart';

final isApple =
    (kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.iOS)) ||
    (!kIsWeb && (Platform.isMacOS || Platform.isIOS));

class ResourceItemGestureHandler extends StatefulWidget {
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
  State<ResourceItemGestureHandler> createState() =>
      _ResourceItemGestureHandlerState();
}

class _ResourceItemGestureHandlerState
    extends State<ResourceItemGestureHandler> {
  bool deferHandling = false;

  @override
  Widget build(BuildContext context) {
    return _TouchGestureHandler(
      resourceIndex: widget.index,
      child: _MouseGestureHandler(
        resourceId: widget.resource.id,
        resourceIndex: widget.index,
        child: ResourceDraggable(
          resource: widget.resource,
          index: widget.index,
          buildItem: widget.buildItem,
        ),
      ),
    );
  }
}

class _TouchGestureHandler extends StatelessWidget {
  final Widget child;
  final int resourceIndex;

  const _TouchGestureHandler({
    required this.resourceIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      supportedDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      },
      onTap: () {
        if (context.read<ExplorerState>().selected.isEmpty) {
          _openResource(context, resourceIndex);
        } else {
          context.read<ExplorerController>().updateSelection(
            (_) => resourceIndex,
            SelectionMode.toggle,
            false,
          );
        }
      },
      onLongPress:
          context.select<ExplorerState, bool>(
            (state) => state.selected.isNotEmpty,
          )
          ? null
          : () {
              context.read<ExplorerController>().updateSelection(
                (_) => resourceIndex,
                SelectionMode.single,
                false,
              );
            },
      child: child,
    );
  }
}

class _MouseGestureHandler extends StatelessWidget {
  final int resourceIndex;
  final String resourceId;
  final Widget child;

  const _MouseGestureHandler({
    required this.resourceId,
    required this.resourceIndex,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        SerialTapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<SerialTapGestureRecognizer>(
              () => SerialTapGestureRecognizer(
                supportedDevices: {.mouse, .trackpad},
              ),
              (recognizer) {
                recognizer.onSerialTapDown = (details) {
                  if (details.buttons == kSecondaryButton) {
                    if (HardwareKeyboard.instance.isShiftPressed ||
                        HardwareKeyboard.instance.isControlPressed ||
                        HardwareKeyboard.instance.isMetaPressed) {
                      return;
                    }
                    showContextMenu(context, details.globalPosition);
                  }
                };
                recognizer.onSerialTapUp = (details) {
                  if (details.count == 1) {
                    Focus.maybeOf(context)?.requestFocus();

                    if (isApple && HardwareKeyboard.instance.isControlPressed) {
                      if (HardwareKeyboard.instance.isShiftPressed ||
                          HardwareKeyboard.instance.isMetaPressed) {
                        return;
                      }
                      showContextMenu(context, details.globalPosition);
                      return;
                    }

                    final mode =
                        ((isApple && HardwareKeyboard.instance.isMetaPressed) ||
                            (!isApple &&
                                HardwareKeyboard.instance.isControlPressed))
                        ? SelectionMode.toggle
                        : HardwareKeyboard.instance.isShiftPressed
                        ? SelectionMode.range
                        : SelectionMode.single;
                    context.read<ExplorerController>().updateSelection(
                      (_) => resourceIndex,
                      mode,
                      false,
                    );
                  } else if (details.count == 2) {
                    _openResource(context, resourceIndex);
                  }
                };
              },
            ),
      },
      child: child,
    );
  }

  void showContextMenu(BuildContext context, Offset offset) async {
    final state = context.read<ExplorerState>();
    var selected = state.selected;
    if (!state.isSelected(resourceId)) {
      context.read<ExplorerController>().updateSelection(
        (i) => resourceIndex,
        SelectionMode.single,
        false,
      );
      selected = context.read<ExplorerState>().selected;
    } else {
      context.read<ExplorerController>().updateSelection(
        null,
        SelectionMode.noChange,
        false,
      );
    }
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy,
      offset.dx,
      offset.dy,
    );
    final items = await buildPopupMenuItems(
      context.read<PhylumAccount>(),
      state.location.selectedResourceOptions,
      selected,
    );
    if (!context.mounted) return;
    final selection = await showMenu(
      context: context,
      position: position,
      items: items.toList(growable: false),
    );
    if (context.mounted && selection != null) {
      handleOption(context, selected, selection);
    }
  }
}

void _openResource(BuildContext context, int index) {
  final resource = context.read<ExplorerState>().resources[index];
  Actions.maybeInvoke(context, OpenResourceIntent(resource));
}
