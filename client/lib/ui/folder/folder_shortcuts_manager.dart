import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SelectionMode {
  single,
  range,
  multi,
}

class ToggleSelectionIntent extends Intent {
  const ToggleSelectionIntent();
}

class FocusUpIntent extends Intent {
  final SelectionMode mode;
  const FocusUpIntent(this.mode);
}

class FocusDownIntent extends Intent {
  final SelectionMode mode;
  const FocusDownIntent(this.mode);
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class NavUpIntent extends Intent {
  const NavUpIntent();
}

class FolderShortcutManager extends ShortcutManager {
  final Function(bool) shiftListener;
  final Function(bool) controlListener;

  FolderShortcutManager({
    required this.shiftListener,
    required this.controlListener,
  }) : super(shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): FocusUpIntent(SelectionMode.single),
          SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): FocusUpIntent(SelectionMode.range),
          SingleActivator(LogicalKeyboardKey.arrowUp, control: true): FocusUpIntent(SelectionMode.multi),
          SingleActivator(LogicalKeyboardKey.arrowDown): FocusDownIntent(SelectionMode.single),
          SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): FocusDownIntent(SelectionMode.range),
          SingleActivator(LogicalKeyboardKey.arrowDown, control: true): FocusDownIntent(SelectionMode.multi),
          SingleActivator(LogicalKeyboardKey.space, control: true): ToggleSelectionIntent(),
          SingleActivator(LogicalKeyboardKey.enter): OpenIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): NavUpIntent(),
        });

  @override
  KeyEventResult handleKeypress(BuildContext context, KeyEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      return KeyEventResult.skipRemainingHandlers;
    }
    if ((event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight)) {
      if (event is KeyDownEvent) {
        shiftListener(true);
      } else if (event is KeyUpEvent) {
        shiftListener(false);
      }
    }
    if ((event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight)) {
      if (event is KeyDownEvent) {
        controlListener(true);
      } else if (event is KeyUpEvent) {
        controlListener(false);
      }
    }
    return super.handleKeypress(context, event);
  }
}
