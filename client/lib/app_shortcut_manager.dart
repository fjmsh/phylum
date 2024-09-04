import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SelectionMode {
  single,
  range,
  multi,
}

class FocusUpIntent extends Intent {
  final SelectionMode mode;
  const FocusUpIntent(this.mode);
}

class FocusDownIntent extends Intent {
  final SelectionMode mode;
  const FocusDownIntent(this.mode);
}

class ToggleSelectionIntent extends Intent {
  const ToggleSelectionIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class NavUpIntent extends Intent {
  const NavUpIntent();
}

Map<ShortcutActivator, Intent> getAppShortcuts() {
  return const {
    SingleActivator(LogicalKeyboardKey.arrowUp): FocusUpIntent(SelectionMode.single),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): FocusUpIntent(SelectionMode.range),
    SingleActivator(LogicalKeyboardKey.arrowUp, control: true): FocusUpIntent(SelectionMode.multi),
    SingleActivator(LogicalKeyboardKey.arrowDown): FocusDownIntent(SelectionMode.single),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): FocusDownIntent(SelectionMode.range),
    SingleActivator(LogicalKeyboardKey.arrowDown, control: true): FocusDownIntent(SelectionMode.multi),
    SingleActivator(LogicalKeyboardKey.space, control: true): ToggleSelectionIntent(),
    SingleActivator(LogicalKeyboardKey.enter): OpenIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): NavUpIntent(),
  };
}
