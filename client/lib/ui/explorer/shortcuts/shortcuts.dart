import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/shortcuts/intents.dart';

Map<ShortcutActivator, Intent>? _shortcutsMap;

Map<ShortcutActivator, Intent> get shortcutsMap {
  _shortcutsMap ??= _createShortcuts();
  return _shortcutsMap!;
}

Map<ShortcutActivator, Intent> _createShortcuts() {
  final isApple =
      (kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.iOS)) ||
      (!kIsWeb && (Platform.isMacOS || Platform.isIOS));
  final shortcuts = {
    // Focus / Selection
    SingleActivator(.arrowUp): FocusUpIntent(.single),
    SingleActivator(.arrowDown): FocusDownIntent(.single),
    SingleActivator(.arrowLeft): FocusLeftIntent(.single),
    SingleActivator(.arrowRight): FocusRightIntent(.single),
    SingleActivator(.home): FocusFirstIntent(.single),
    SingleActivator(.end): FocusLastIntent(.single),
    SingleActivator(.space): ActivateIntent(),

    SingleActivator(.arrowUp, shift: true): FocusUpIntent(.range),
    SingleActivator(.arrowDown, shift: true): FocusDownIntent(.range),
    SingleActivator(.arrowLeft, shift: true): FocusLeftIntent(.range),
    SingleActivator(.arrowRight, shift: true): FocusRightIntent(.range),
    SingleActivator(.home, shift: true): FocusFirstIntent(.range),
    SingleActivator(.end, shift: true): FocusLastIntent(.range),
    SingleActivator(.space, shift: true): ToggleSelectionIntent(),

    SingleActivator(.enter): ActivateIntent(),
    SingleActivator(.space): ActivateIntent(),
    SingleActivator(.f2): RenameIntent(),
    SingleActivator(.f5): RefreshIntent(),
    CharacterActivator('#'): DeleteIntent(false),
  };

  if (isApple) {
    shortcuts.addAll({
      // Selection
      SingleActivator(.arrowUp, meta: true): FocusUpIntent(.noChange),
      SingleActivator(.arrowDown, meta: true): FocusDownIntent(.noChange),
      SingleActivator(.arrowLeft, meta: true): FocusLeftIntent(.noChange),
      SingleActivator(.arrowRight, meta: true): FocusRightIntent(.noChange),
      SingleActivator(.home, meta: true): FocusFirstIntent(.noChange),
      SingleActivator(.end, meta: true): FocusLastIntent(.noChange),
      SingleActivator(.space, meta: true): ToggleSelectionIntent(),

      // Navigation
      // SingleActivator(.arrowUp, meta: true): NavUpIntent(),
      // SingleActivator(.arrowDown, meta: true): ActivateIntent(),
      // SingleActivator(.arrowLeft, meta: true): NavBackIntent(),
      // SingleActivator(.arrowRight, meta: true): NavForwardIntent(),
      SingleActivator(.bracketLeft, meta: true): NavBackIntent(),
      SingleActivator(.bracketRight, meta: true): NavForwardIntent(),
      SingleActivator(.keyH, meta: true): NavHomeIntent(),
      SingleActivator(.keyF, meta: true): FocusSearchIntent(),

      // Creation in parent folder
      SingleActivator(.keyN, meta: true, shift: true): NewFolderIntent(),
      SingleActivator(.keyU, meta: true): UploadFilesIntent(),
      SingleActivator(.keyU, meta: true, shift: true): UploadFolderIntent(),

      // Selection
      SingleActivator(.keyA, meta: true): SelectAllIntent(),
      SingleActivator(.backspace, meta: true): DeleteIntent(false),
      SingleActivator(.backspace, meta: true, shift: true): DeleteIntent(true),

      // Clipboard
      SingleActivator(.keyC, meta: true): CopyToClipboardIntent(false),
      SingleActivator(.keyX, meta: true): CopyToClipboardIntent(true),
      if (!kIsWeb)
        SingleActivator(.keyV, meta: true): PasteFromClipboardIntent(),

      // Misc
      SingleActivator(.keyR, meta: true): RefreshIntent(),
    });
  } else {
    shortcuts.addAll({
      // Selection
      SingleActivator(.arrowUp, control: true): FocusUpIntent(.noChange),
      SingleActivator(.arrowDown, control: true): FocusDownIntent(.noChange),
      SingleActivator(.arrowLeft, control: true): FocusLeftIntent(.noChange),
      SingleActivator(.arrowRight, control: true): FocusRightIntent(.noChange),
      SingleActivator(.home, control: true): FocusFirstIntent(.noChange),
      SingleActivator(.end, control: true): FocusLastIntent(.noChange),
      SingleActivator(.space, control: true): ToggleSelectionIntent(),

      // Navigation
      SingleActivator(.arrowUp, alt: true): NavUpIntent(),
      SingleActivator(.arrowLeft, alt: true): NavBackIntent(),
      SingleActivator(.arrowRight, alt: true): NavForwardIntent(),
      SingleActivator(.keyH, control: true): NavHomeIntent(),
      SingleActivator(.keyF, control: true): FocusSearchIntent(),

      // Creation in parent folder
      SingleActivator(.keyN, control: true): NewFolderIntent(),
      SingleActivator(.keyU, control: true): UploadFilesIntent(),
      SingleActivator(.keyU, control: true, shift: true): UploadFolderIntent(),

      // Selection
      SingleActivator(.keyA, control: true): SelectAllIntent(),
      SingleActivator(.delete): DeleteIntent(false),
      SingleActivator(.delete, shift: true): DeleteIntent(true),

      // Clipboard
      SingleActivator(.keyC, control: true): CopyToClipboardIntent(false),
      SingleActivator(.keyX, control: true): CopyToClipboardIntent(true),
      if (!kIsWeb)
        SingleActivator(.keyV, control: true): PasteFromClipboardIntent(),

      // Misc
      SingleActivator(.keyR, control: true): RefreshIntent(),
    });
  }
  return shortcuts;
}
