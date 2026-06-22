import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
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
  final bool permanent;
  const DeleteIntent(this.permanent);
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
  final ExplorerLocation target;

  const NavIntent({required this.target});
}

class RefreshIntent extends Intent {
  const RefreshIntent();
}

class FocusSearchIntent extends Intent {
  const FocusSearchIntent();
}

class OpenResourceIntent extends Intent {
  final Resource resource;

  const OpenResourceIntent(this.resource);
}

Map<ShortcutActivator, Intent>? _appShortcuts;

Map<ShortcutActivator, Intent> get appShortcuts {
  _appShortcuts ??= createShortcuts();
  return _appShortcuts!;
}

Map<ShortcutActivator, Intent> createShortcuts() {
  final isApple =
      (kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.iOS)) ||
      (!kIsWeb && (Platform.isMacOS || Platform.isIOS));
  final shortcuts = {
    // Add basic intents
    SingleActivator(LogicalKeyboardKey.tab): NextFocusIntent(),
    SingleActivator(LogicalKeyboardKey.tab, shift: true): PreviousFocusIntent(),
    SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),

    // Focus / Selection
    // Up
    SingleActivator(LogicalKeyboardKey.arrowUp): FocusUpIntent(
      SelectionMode.single,
    ),
    SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): FocusUpIntent(
      SelectionMode.range,
    ),

    // Down
    SingleActivator(LogicalKeyboardKey.arrowDown): FocusDownIntent(
      SelectionMode.single,
    ),
    SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): FocusDownIntent(
      SelectionMode.range,
    ),

    // Left
    SingleActivator(LogicalKeyboardKey.arrowLeft): FocusLeftIntent(
      SelectionMode.single,
    ),
    SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): FocusLeftIntent(
      SelectionMode.range,
    ),

    // Right
    SingleActivator(LogicalKeyboardKey.arrowRight): FocusRightIntent(
      SelectionMode.single,
    ),
    SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
        FocusRightIntent(SelectionMode.range),

    // Home
    SingleActivator(LogicalKeyboardKey.home): FocusFirstIntent(
      SelectionMode.single,
    ),
    SingleActivator(LogicalKeyboardKey.home, shift: true): FocusFirstIntent(
      SelectionMode.range,
    ),

    // End
    SingleActivator(LogicalKeyboardKey.end): FocusLastIntent(
      SelectionMode.single,
    ),
    SingleActivator(LogicalKeyboardKey.end, shift: true): FocusLastIntent(
      SelectionMode.range,
    ),
  };

  if (isApple) {
    shortcuts.addAll({
      // Navigation
      SingleActivator(LogicalKeyboardKey.arrowUp, meta: true): NavUpIntent(),
      SingleActivator(LogicalKeyboardKey.keyH, meta: true): NavHomeIntent(),
      SingleActivator(LogicalKeyboardKey.keyF, meta: true): FocusSearchIntent(),
      SingleActivator(LogicalKeyboardKey.bracketLeft, meta: true):
          NavBackIntent(),
      SingleActivator(LogicalKeyboardKey.bracketRight, meta: true):
          NavForwardIntent(),

      // Creation in parent folder
      SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true):
          NewFolderIntent(),
      SingleActivator(LogicalKeyboardKey.keyU, meta: true): UploadFilesIntent(),
      SingleActivator(LogicalKeyboardKey.keyU, meta: true, shift: true):
          UploadFolderIntent(),

      // Selection
      SingleActivator(LogicalKeyboardKey.keyA, meta: true): SelectAllIntent(),
      SingleActivator(LogicalKeyboardKey.arrowDown, meta: true):
          ActivateIntent(),
      // TODO: show properties
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.enter): RenameIntent(),
      SingleActivator(LogicalKeyboardKey.delete, meta: true): DeleteIntent(
        false,
      ),
      SingleActivator(LogicalKeyboardKey.delete, meta: true, shift: true):
          DeleteIntent(true),

      // Clipboard
      SingleActivator(LogicalKeyboardKey.keyC, meta: true):
          CopyToClipboardIntent(false),
      SingleActivator(LogicalKeyboardKey.keyX, meta: true):
          CopyToClipboardIntent(true),
      SingleActivator(LogicalKeyboardKey.keyV, meta: true):
          PasteFromClipboardIntent(),

      // Misc
      SingleActivator(LogicalKeyboardKey.f5): RefreshIntent(),
      SingleActivator(LogicalKeyboardKey.keyR, meta: true): RefreshIntent(),
    });
  } else {
    // Disjoint multi-select
    shortcuts.addAll({
      SingleActivator(LogicalKeyboardKey.arrowUp, control: true): FocusUpIntent(
        SelectionMode.noChange,
      ),
      SingleActivator(LogicalKeyboardKey.arrowDown, control: true):
          FocusDownIntent(SelectionMode.noChange),
      SingleActivator(LogicalKeyboardKey.arrowLeft, control: true):
          FocusLeftIntent(SelectionMode.noChange),
      SingleActivator(LogicalKeyboardKey.arrowRight, control: true):
          FocusRightIntent(SelectionMode.noChange),
      SingleActivator(LogicalKeyboardKey.home, control: true): FocusFirstIntent(
        SelectionMode.noChange,
      ),
      SingleActivator(LogicalKeyboardKey.end, control: true): FocusLastIntent(
        SelectionMode.noChange,
      ),
      SingleActivator(LogicalKeyboardKey.space, control: true):
          ToggleSelectionIntent(),
    });

    shortcuts.addAll({
      // Navigation
      SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): NavUpIntent(),
      SingleActivator(LogicalKeyboardKey.keyH, control: true): NavHomeIntent(),
      SingleActivator(LogicalKeyboardKey.keyF, control: true):
          FocusSearchIntent(),
      SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): NavBackIntent(),
      SingleActivator(LogicalKeyboardKey.arrowRight, alt: true):
          NavForwardIntent(),

      // Creation in parent folder
      SingleActivator(LogicalKeyboardKey.keyN, control: true):
          NewFolderIntent(),
      SingleActivator(LogicalKeyboardKey.keyU, control: true):
          UploadFilesIntent(),
      SingleActivator(LogicalKeyboardKey.keyU, control: true, shift: true):
          UploadFolderIntent(),

      // Selection
      SingleActivator(LogicalKeyboardKey.keyA, control: true):
          SelectAllIntent(),
      SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      SingleActivator(LogicalKeyboardKey.keyE, control: true): RenameIntent(),
      SingleActivator(LogicalKeyboardKey.f2): RenameIntent(),
      SingleActivator(LogicalKeyboardKey.delete): DeleteIntent(false),
      SingleActivator(LogicalKeyboardKey.delete, shift: true): DeleteIntent(
        true,
      ),

      // Clipboard
      SingleActivator(LogicalKeyboardKey.keyC, control: true):
          CopyToClipboardIntent(false),
      SingleActivator(LogicalKeyboardKey.keyX, control: true):
          CopyToClipboardIntent(true),
      SingleActivator(LogicalKeyboardKey.keyV, control: true):
          PasteFromClipboardIntent(),

      // Misc
      SingleActivator(LogicalKeyboardKey.f5): RefreshIntent(),
      SingleActivator(LogicalKeyboardKey.keyR, control: true): RefreshIntent(),
    });
  }
  return shortcuts;
}
