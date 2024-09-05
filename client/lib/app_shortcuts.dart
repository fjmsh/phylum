import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SelectionMode {
  single,
  range,
  multi,
  toggle,
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

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class CutToClipboardIntent extends Intent {
  const CutToClipboardIntent();
}

class CopyToClipboardIntent extends Intent {
  const CopyToClipboardIntent();
}

class PasteFromClipboardIntent extends Intent {
  const PasteFromClipboardIntent();
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
    SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
    SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp): FocusUpIntent(SelectionMode.single),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): FocusUpIntent(SelectionMode.range),
    SingleActivator(LogicalKeyboardKey.arrowUp, control: true): FocusUpIntent(SelectionMode.multi),
    SingleActivator(LogicalKeyboardKey.arrowDown): FocusDownIntent(SelectionMode.single),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): FocusDownIntent(SelectionMode.range),
    SingleActivator(LogicalKeyboardKey.arrowDown, control: true): FocusDownIntent(SelectionMode.multi),
    SingleActivator(LogicalKeyboardKey.space, control: true): ToggleSelectionIntent(),
    SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllIntent(),
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): NavUpIntent(),
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.keyN, control: true): NewFolderIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, control: true): UploadFilesIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, control: true, shift: true): UploadFolderIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopyToClipboardIntent(),
    SingleActivator(LogicalKeyboardKey.keyX, control: true): CutToClipboardIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteFromClipboardIntent(),
  };
}
