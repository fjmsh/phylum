import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:phylum/ui/folder/resource_options_dialog.dart';
import 'package:provider/provider.dart';

import 'folder_navigator_stack.dart';

class FolderContentsView extends StatefulWidget {
  final String id;

  FolderContentsView({required this.id}) : super(key: ValueKey(id));

  @override
  State<FolderContentsView> createState() => _FolderContentsViewState();
}

class FolderShortcutManager extends ShortcutManager {
  FolderShortcutManager()
      : super(shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowUp): FocusUpIntent(),
          SingleActivator(LogicalKeyboardKey.keyK): FocusUpIntent(),
          SingleActivator(LogicalKeyboardKey.arrowDown): FocusDownIntent(),
          SingleActivator(LogicalKeyboardKey.enter): OpenIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): NavUpIntent(),
        });

  @override
  KeyEventResult handleKeypress(BuildContext context, KeyEvent event) {
    if ((event.logicalKey == LogicalKeyboardKey.shiftLeft || event.logicalKey == LogicalKeyboardKey.shiftRight)) {
      if (event is KeyDownEvent) {
        print('Shift Pressed');
      } else if (event is KeyUpEvent) {
        print('Shift Released');
      }
    }
    return super.handleKeypress(context, event);
  }
}

class _FolderContentsViewState extends State<FolderContentsView> {
  late final FocusNode _node;
  final shortcutManager = FolderShortcutManager();
  final Map<String, FocusNode> nodes = {};
  int focusIndex = -1;
  List<Resource>? resources;

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
                        focusIndex = focusIndex > 0 ? focusIndex - 1 : 0;
                        getFocusNode(resources![focusIndex]).requestFocus();
                        return null;
                      }),
                      FocusDownIntent: CallbackAction<FocusDownIntent>(onInvoke: (i) {
                        focusIndex = focusIndex < resources!.length - 1 ? focusIndex + 1 : resources!.length - 1;
                        getFocusNode(resources![focusIndex]).requestFocus();
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
                      child: ListView(
                        children: [
                          for (final r in resources!.indexed)
                            Focus(
                              focusNode: getFocusNode(r.$2),
                              child: ResourceListTile(
                                  r: r.$2,
                                  onTap: () {
                                    focusIndex = r.$1;
                                    getFocusNode(r.$2).requestFocus();
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
    );
  }

  void open(Resource r) {
    if (r.dir) context.read<FolderNavigatorStack>().push(r.id, r.name);
  }

  FocusNode getFocusNode(Resource r) {
    return nodes.putIfAbsent(r.id, () => FocusNode());
  }
}

class FocusUpIntent extends Intent {
  const FocusUpIntent();
}

class FocusDownIntent extends Intent {
  const FocusDownIntent();
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class NavUpIntent extends Intent {
  const NavUpIntent();
}

class ResourceListTile extends StatelessWidget {
  final Resource r;
  final Function()? onTap;
  final Function()? onDoubleTap;
  final Function()? onSecondaryTap;

  ResourceListTile({required this.r, this.onTap, this.onDoubleTap, this.onSecondaryTap}) : super(key: ValueKey(r.id));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => onTap?.call(),
        onDoubleTap: () => onDoubleTap?.call(),
        onSecondaryTap: () => onSecondaryTap?.call(),
        child: Container(
          decoration: Focus.isAt(context)
              ? const BoxDecoration(border: Border.fromBorderSide(BorderSide(color: Colors.blue, width: 2.0)))
              : const BoxDecoration(border: Border.fromBorderSide(BorderSide(color: Colors.transparent, width: 2.0))),
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: Row(
            children: [r.getIcon(), Expanded(child: Text(r.name)), ResourceOptionsButton(r: r)],
          ),
        ));
  }
}

extension ResourceViewExtensions on Resource {
  Icon getIcon() {
    if (dir) return const Icon(Icons.folder);
    final index = name.lastIndexOf('.');
    final ext = index > 0 ? name.substring(index + 1).toLowerCase() : '';
    return switch (ext) {
      'bmp' || 'png' || 'jpg' || 'jpeg' || 'gif' || 'webp' || 'heic' || 'heif' || 'svg' => const Icon(Icons.image),
      'webm' || 'avi' || 'mp4' || 'mov' => const Icon(Icons.movie),
      'mp3' || 'mp4' || 'm4a' || 'ogg' || 'oga' => const Icon(Icons.headphones),
      'txt' || 'csv' => const Icon(Icons.article),
      _ => const Icon(Icons.insert_drive_file),
    };
  }
}
