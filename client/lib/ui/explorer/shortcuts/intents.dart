import 'package:flutter/widgets.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/explorer/shortcuts/selection_mode.dart';

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
