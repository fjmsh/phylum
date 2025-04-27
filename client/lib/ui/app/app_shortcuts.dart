import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/ui/explorer/page.dart';
import 'package:phylum/ui/explorer/selection_mode.dart';

class FocusUpIntent extends Intent {
  final SelectionMode mode;

  const FocusUpIntent(this.mode);
}

class FocusDownIntent extends Intent {
  final SelectionMode mode;

  const FocusDownIntent(this.mode);
}

class FocusRightIntent extends Intent {
  final SelectionMode mode;

  const FocusRightIntent(this.mode);
}

class FocusLeftIntent extends Intent {
  final SelectionMode mode;

  const FocusLeftIntent(this.mode);
}

class FocusFirstIntent extends Intent {
  final SelectionMode mode;

  const FocusFirstIntent(this.mode);
}

class FocusLastIntent extends Intent {
  final SelectionMode mode;

  const FocusLastIntent(this.mode);
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

class NavBackIntent extends Intent {
  const NavBackIntent();
}

class NavForwardIntent extends Intent {
  const NavForwardIntent();
}

class NavUpIntent extends Intent {
  const NavUpIntent();
}

class NavHomeIntent extends Intent {
  const NavHomeIntent();
}

class NavIntent extends Intent {
  final ExplorerPage target;

  const NavIntent({required this.target});
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

Map<ShortcutActivator, Intent> get appShortcuts => const {
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
      SingleActivator(LogicalKeyboardKey.arrowLeft): FocusLeftIntent(SelectionMode.single),
      SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): FocusLeftIntent(SelectionMode.range),
      SingleActivator(LogicalKeyboardKey.arrowLeft, control: true): FocusLeftIntent(SelectionMode.noChange),
      SingleActivator(LogicalKeyboardKey.arrowRight): FocusRightIntent(SelectionMode.single),
      SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): FocusRightIntent(SelectionMode.range),
      SingleActivator(LogicalKeyboardKey.arrowRight, control: true): FocusRightIntent(SelectionMode.noChange),
      SingleActivator(LogicalKeyboardKey.home): FocusFirstIntent(SelectionMode.single),
      SingleActivator(LogicalKeyboardKey.home, shift: true): FocusFirstIntent(SelectionMode.range),
      SingleActivator(LogicalKeyboardKey.home, control: true): FocusFirstIntent(SelectionMode.noChange),
      SingleActivator(LogicalKeyboardKey.end): FocusLastIntent(SelectionMode.single),
      SingleActivator(LogicalKeyboardKey.end, shift: true): FocusLastIntent(SelectionMode.range),
      SingleActivator(LogicalKeyboardKey.end, control: true): FocusLastIntent(SelectionMode.noChange),
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
      SingleActivator(LogicalKeyboardKey.keyS, alt: true): FocusSearchIntent(),
      if (!kIsWeb) SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): NavBackIntent(),
      if (!kIsWeb) SingleActivator(LogicalKeyboardKey.arrowRight, alt: true): NavForwardIntent(),
    };
