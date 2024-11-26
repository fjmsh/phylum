import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/libphylum/explorer/selection_mode.dart';

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

class CopyToClipboardIntent extends Intent {
  final bool cut;

  const CopyToClipboardIntent(this.cut);
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

class NavBackIntent extends Intent {
  const NavBackIntent();
}

class NavForwardIntent extends Intent {
  const NavForwardIntent();
}

class NavHomeIntent extends Intent {
  const NavHomeIntent();
}

class NavToFolderIntent extends Intent {
  final String folderId;

  const NavToFolderIntent({required this.folderId});
}

Map<ShortcutActivator, Intent> getAppShortcuts() {
  return const {
    // General
    SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
    SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
    SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),

    // Focus / Selection
    SingleActivator(LogicalKeyboardKey.arrowUp): FocusUpIntent(SelectionMode.single),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): FocusUpIntent(SelectionMode.range),
    SingleActivator(LogicalKeyboardKey.arrowUp, control: true): FocusUpIntent(SelectionMode.noChange),
    SingleActivator(LogicalKeyboardKey.arrowDown): FocusDownIntent(SelectionMode.single),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): FocusDownIntent(SelectionMode.range),
    SingleActivator(LogicalKeyboardKey.arrowDown, control: true): FocusDownIntent(SelectionMode.noChange),
    SingleActivator(LogicalKeyboardKey.space, control: true): ToggleSelectionIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllIntent(),

    // Actions for selection
    SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
    SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(),
    SingleActivator(LogicalKeyboardKey.keyC, control: true): CopyToClipboardIntent(false),
    SingleActivator(LogicalKeyboardKey.keyX, control: true): CopyToClipboardIntent(true),
    SingleActivator(LogicalKeyboardKey.keyE, control: true): RenameIntent(),
    SingleActivator(LogicalKeyboardKey.f2): RenameIntent(),

    // Actions for folder
    SingleActivator(LogicalKeyboardKey.keyN, control: true): NewFolderIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, control: true): UploadFilesIntent(),
    SingleActivator(LogicalKeyboardKey.keyU, control: true, shift: true): UploadFolderIntent(),
    SingleActivator(LogicalKeyboardKey.keyV, control: true): PasteFromClipboardIntent(),

    // Top-level Navigation
    SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): NavUpIntent(),
    SingleActivator(LogicalKeyboardKey.keyH, alt: true): NavHomeIntent(),
    if (!kIsWeb) SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): NavBackIntent(),
    if (!kIsWeb) SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): NavForwardIntent(),
  };
}
