import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:phylum/ui/folder/folder_selection_manager.dart';
import 'package:phylum/ui/folder/folder_shortcuts_manager.dart';
import 'package:phylum/ui/folder/resource_details_row.dart';
import 'package:provider/provider.dart';

import 'folder_navigator_stack.dart';

class FolderContentsView extends StatefulWidget {
  final String id;

  FolderContentsView({required this.id}) : super(key: ValueKey(id));

  @override
  State<FolderContentsView> createState() => _FolderContentsViewState();
}

class _FolderContentsViewState extends State<FolderContentsView> {
  late final FocusNode _node;
  late final shortcutManager = FolderShortcutManager(
    shiftListener: (state) {
      shiftDown = state;
    },
    controlListener: (state) {
      controlDown = state;
    },
  );
  final Map<String, FocusNode> nodes = {};
  int focusIndex = -1;
  int selectionStartIndex = -1;
  List<Resource>? resources;
  bool shiftDown = false;
  bool controlDown = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _node = FocusNode(
      debugLabel: 'Folder Contents View',
    );
  }

  @override
  void dispose() {
    for (final n in nodes.values) {
      n.dispose();
    }
    shortcutManager.dispose();
    _node.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<PhylumAccount>().api.sendRequest(ResourceDetailRequest(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();

    return ListTileTheme(
      data: ListTileThemeData(mouseCursor: WidgetStateProperty.all(SystemMouseCursors.basic)),
      child: Shortcuts.manager(
        manager: shortcutManager,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: Center(
            child: StateNotifierProvider<FolderSelectionManager, FolderSelectionState>(
              create: (context) => FolderSelectionManager(),
              child: StreamBuilder(
                  stream: account.datastore.db.managers.resources.filter((f) => f.parent.id.equals(widget.id) & f.deleted.equals(false)).watch(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container();
                    }
                    resources = snapshot.data!;
                    return Actions(
                      actions: {
                        FocusUpIntent: CallbackAction<FocusUpIntent>(onInvoke: (i) {
                          if (resources!.isEmpty) return;
                          final newIndex = focusIndex == -1
                              ? resources!.length
                              : focusIndex > 0
                                  ? focusIndex - 1
                                  : 0;
                          final selectedResource = resources![newIndex];
                          getFocusNode(selectedResource).requestFocus();
                          switch (i.mode) {
                            case SelectionMode.range:
                              if (selectionStartIndex == -1) {
                                selectionStartIndex = newIndex;
                              }
                              final selected = Set.of(
                                  resources!.getRange(min(selectionStartIndex, newIndex), max(selectionStartIndex, newIndex) + 1).map((r) => r.id));
                              context.read<FolderSelectionManager>().setSelected(selected);
                            case SelectionMode.single:
                              context.read<FolderSelectionManager>().setSelected({selectedResource.id});
                              selectionStartIndex = newIndex;
                              break;
                            case SelectionMode.multi:
                              break;
                          }
                          focusIndex = newIndex;
                          return null;
                        }),
                        FocusDownIntent: CallbackAction<FocusDownIntent>(onInvoke: (i) {
                          if (resources!.isEmpty) return;
                          final newIndex = focusIndex < resources!.length - 1 ? focusIndex + 1 : resources!.length - 1;
                          final selectedResource = resources![newIndex];
                          getFocusNode(selectedResource).requestFocus();
                          switch (i.mode) {
                            case SelectionMode.range:
                              if (selectionStartIndex == -1) {
                                selectionStartIndex = newIndex;
                              }
                              final selected = Set.of(
                                  resources!.getRange(min(selectionStartIndex, newIndex), max(selectionStartIndex, newIndex) + 1).map((r) => r.id));
                              context.read<FolderSelectionManager>().setSelected(selected);
                            case SelectionMode.single:
                              context.read<FolderSelectionManager>().setSelected({selectedResource.id});
                              selectionStartIndex = newIndex;
                              break;
                            case SelectionMode.multi:
                              break;
                          }
                          focusIndex = newIndex;
                          return null;
                        }),
                        ToggleSelectionIntent: CallbackAction<ToggleSelectionIntent>(onInvoke: (i) {
                          final selectedResource = resources![focusIndex];
                          selectionStartIndex = context.read<FolderSelectionManager>().toggleSelected(selectedResource.id) ? focusIndex : -1;
                          return null;
                        }),
                        OpenIntent: CallbackAction<OpenIntent>(onInvoke: (i) {
                          open(resources![focusIndex]);
                          return null;
                        }),
                        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) {
                          context.read<FolderNavigatorStack>().pop();
                          return null;
                        }),
                      },
                      child: Focus(
                        autofocus: true,
                        focusNode: _node,
                        onFocusChange: (hasFocus) {
                          shiftDown = false;
                          controlDown = false;
                        },
                        child: ListView(
                          children: [
                            for (final r in resources!.indexed)
                              Focus(
                                focusNode: getFocusNode(r.$2),
                                child: ResourceDetailsRow(
                                    r: r.$2,
                                    onTap: () {
                                      final newIndex = r.$1;
                                      if (controlDown) {
                                        selectionStartIndex = context.read<FolderSelectionManager>().toggleSelected(r.$2.id) ? newIndex : -1;
                                      } else if (shiftDown) {
                                        if (selectionStartIndex == -1) {
                                          selectionStartIndex = newIndex;
                                        }
                                        final selected = Set.of(resources!
                                            .getRange(min(selectionStartIndex, newIndex), max(selectionStartIndex, newIndex) + 1)
                                            .map((r) => r.id));
                                        context.read<FolderSelectionManager>().setSelected(selected);
                                      } else {
                                        selectionStartIndex = r.$1;
                                        context.read<FolderSelectionManager>().setSelected({r.$2.id});
                                      }
                                      getFocusNode(r.$2).requestFocus();
                                      focusIndex = newIndex;
                                    },
                                    onDoubleTap: () => open(r.$2)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ),
        ),
      ),
    );
  }

  void open(Resource r) {
    if (r.dir) context.read<FolderNavigatorStack>().push(r.id, r.name);
  }

  FocusNode getFocusNode(Resource r) {
    return nodes.putIfAbsent(r.id, () => FocusNode(descendantsAreTraversable: false));
  }
}
