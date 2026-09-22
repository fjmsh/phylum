import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:phylum/ui/explorer/explorer_controller.dart';
import 'package:phylum/ui/explorer/menu/context_menu_helper.dart';
import 'package:phylum/ui/explorer/menu/option_groups.dart';
import 'package:phylum/ui/explorer/menu/option_handler.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';
import 'package:phylum/util/platform.dart';
import 'package:provider/provider.dart';

class ItemMouseGestureHandler extends StatelessWidget {
  final int resourceIndex;
  final String resourceId;
  final Widget child;

  ItemMouseGestureHandler({
    required this.resourceId,
    required this.resourceIndex,
    required this.child,
  }) : super(key: ValueKey(resourceId));

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        TapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
              () => TapGestureRecognizer(
                supportedDevices: {.mouse, .trackpad},
                allowedButtonsFilter: (buttons) => buttons == kSecondaryButton,
              ),
              (recognizer) {
                recognizer.onSecondaryTapUp = (details) {
                  if (HardwareKeyboard.instance.isShiftPressed ||
                      HardwareKeyboard.instance.isControlPressed ||
                      HardwareKeyboard.instance.isMetaPressed) {
                    return;
                  }
                  _showContextMenu(context, details.globalPosition);
                };
              },
            ),
        SerialTapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<SerialTapGestureRecognizer>(
              () => SerialTapGestureRecognizer(
                supportedDevices: {.mouse, .trackpad},
                allowedButtonsFilter: (buttons) => buttons == kPrimaryButton,
              ),
              (recognizer) {
                recognizer.onSerialTapUp = (details) {
                  if (details.count == 1) {
                    Focus.maybeOf(context)?.requestFocus();

                    if (isApple && HardwareKeyboard.instance.isControlPressed) {
                      if (HardwareKeyboard.instance.isShiftPressed ||
                          HardwareKeyboard.instance.isMetaPressed) {
                        return;
                      }
                      _showContextMenu(context, details.globalPosition);
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
                    final resource = context
                        .read<ExplorerState>()
                        .resources[resourceIndex];
                    Actions.maybeInvoke(context, OpenResourceIntent(resource));
                  }
                };
              },
            ),
      },
      child: child,
    );
  }

  void _showContextMenu(BuildContext context, Offset offset) async {
    final state = context.read<ExplorerState>();
    var resources = state.selected;

    if (!state.isSelected(resourceId)) {
      context.read<ExplorerController>().updateSelection(
        (i) => resourceIndex,
        .single,
        false,
      );
      resources = context.read<ExplorerState>().selected;
    } else {
      context.read<ExplorerController>().updateSelection(
        null,
        .noChange,
        false,
      );
    }
    final groups = await getEnabledOptions(
      context.read(),
      state.location.selectedResourceOptions,
      resources,
    );

    if (!context.mounted) return;

    ContextMenuHelper.show(
      context: context,
      position: offset,
      groups: groups,
      onOptionSelected: (option) {
        if (context.mounted) {
          handleOption(context, resources, option);
        }
      },
    );
  }
}
