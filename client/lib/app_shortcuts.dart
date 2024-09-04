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

class ClearSelectionIntent extends Intent {
  const ClearSelectionIntent();
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class RenameIntent extends Intent {
  const RenameIntent();
}

class NewFolderIntent extends Intent {
  const NewFolderIntent();
}

class UploadFilesIntent extends Intent {
  const UploadFilesIntent();
}

class UploadFolderIntent extends Intent {
  const UploadFolderIntent();
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
    SingleActivator(LogicalKeyboardKey.escape): ClearSelectionIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): NavUpIntent(),
    SingleActivator(LogicalKeyboardKey.enter): OpenIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.keyN, control: true): NewFolderIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, control: true): UploadFilesIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, control: true, shift: true): UploadFolderIntent(),
  };
}
