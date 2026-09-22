import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/local_upload_errors.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/repositories/resource_repository.dart';
import 'package:phylum/libphylum/requests/bootstrap_request.dart';
import 'package:phylum/ui/explorer/destination_picker/destination_picker.dart';
import 'package:phylum/ui/explorer/menu/context_menu_helper.dart';
import 'package:phylum/ui/explorer/menu/option_groups.dart';
import 'package:phylum/ui/explorer/menu/option_handler.dart';
import 'package:phylum/ui/explorer/shortcuts/actions.dart';
import 'package:phylum/ui/explorer/gesture_handlers/folder_gesture_handler.dart';
import 'package:phylum/ui/explorer/item_views/folder_view_type.dart';
import 'package:phylum/ui/explorer/shortcuts/shortcuts.dart';
import 'package:phylum/ui/explorer/path_view.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/util/upload/paste_utils.dart';
import 'package:phylum/util/clippy/clippy.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload/upload_utils.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'explorer_controller.dart';
import 'folder_empty_view.dart';
import 'item_views/grid/folder_grid_view.dart';
import 'item_views/list/folder_list_view.dart';

class ExplorerView extends StatefulWidget {
  final FocusNode _explorerFocusNode;
  final bool _showSelectedItems;

  const ExplorerView({
    super.key,
    required this._explorerFocusNode,
    required this._showSelectedItems,
  });

  @override
  State<ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends State<ExplorerView> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  late final AppLifecycleListener _listener;
  StreamSubscription? _intentSub;

  @override
  void initState() {
    super.initState();

    final account = context.read<PhylumAccount>();
    _listener = AppLifecycleListener(
      onResume: () {
        account.apiClient.sendRequest(
          BootstrapRequest(since: account.bootstrapUntil),
        );
      },
    );

    if (!kIsWeb && Platform.isAndroid) {
      // Process share intents received while the app is alive
      _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((
        value,
      ) {
        handleShareIntent(
          value,
        ).then((value) => ReceiveSharingIntent.instance.reset());
      });

      // Process share intents received while the app is closed
      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        handleShareIntent(
          value,
        ).then((value) => ReceiveSharingIntent.instance.reset());
      });
    }
    Clippy.setPasteHandler((data) {
      final folderId = context.read<ExplorerState>().folderId;
      if (folderId == null) {
        showAlertDialog(context, title: 'Cannot paste here');
        return;
      }
      pasteItems(context, folderId, data);
    });
  }

  @override
  void dispose() {
    _listener.dispose();
    _intentSub?.cancel();
    Clippy.setPasteHandler(null);
    super.dispose();
  }

  Future<void> handleShareIntent(List<SharedMediaFile> shared) async {
    shared.removeWhere(
      (f) => f.type == SharedMediaType.text || f.type == SharedMediaType.url,
    );
    if (shared.isEmpty) return;
    final files = shared
        .map(
          (s) => UploadFile(
            size: File(s.path).lengthSync(),
            stream: File(s.path).openRead().cast<Uint8List>(),
            path: s.path,
          ),
        )
        .toList(growable: false);
    final account = context.read<PhylumAccount>();
    final dest = await DestinationPicker.show(
      context,
      allowInitialFolder: true,
    );
    if (dest == null) {
      return;
    }
    final userPermission =
        await account.db.getResource(dest).then((r) => r?.userPermission) ?? 0;
    if (!context.mounted) return;
    for (final f in files) {
      if (!mounted) return;
      final name = await showInputDialog(
        context,
        hintText: 'File name',
        preset: p.basename(f.path),
      );
      if (!mounted || name == null) return;
      await handleLocalErrors(
        context,
        name,
        overwriteFn: (r) => r.dir ? nameConflictDelete : nameConflictOverwrite,
        (name, conflictResolution, ensurePermission) =>
            account.resourceRepository.upload(
              parent: dest,
              name: name,
              contents: f.stream,
              size: f.size,
              conflictResolution: conflictResolution,
              userPermission: userPermission,
              ensurePermission: ensurePermission,
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final selected = context.select<ExplorerState, Iterable<Resource>>(
      (state) => state.selected,
    );
    final collapsed = width < maxViewportWidthSmall;
    return Shortcuts(
      shortcuts: shortcutsMap,
      child: ExplorerActions(
        explorerFocusNode: widget._explorerFocusNode,
        refreshKey: _refreshKey,
        child: ChangeNotifierProvider(
          create: (context) => FolderViewNotifier(context),
          child: FolderGestureHandler(
            child: Column(
              children: [
                Padding(
                  padding: collapsed
                      ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
                      : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 150),
                    child: widget._showSelectedItems && selected.isNotEmpty
                        ? SelectedResourceView(resources: selected)
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: PathView(small: collapsed)),
                              width < maxViewportWidthLarge
                                  ? const FolderViewIconButton()
                                  : const FolderViewToggleButton(),
                            ],
                          ),
                  ),
                ),
                Expanded(child: Builder(builder: buildPage)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildPage(BuildContext context) {
    final type = context.select<ExplorerState, FolderEmptyViewType?>((state) {
      if (state.resources.isEmpty) {
        if (state.refresh != null) {
          return FolderEmptyViewType.loading;
        }
        if (state.refreshError) {
          return FolderEmptyViewType.error;
        }
        return FolderEmptyViewType.noData;
      }
      return null;
    });
    if (type != null) {
      return FolderEmptyView(
        type: type,
        refreshKey: _refreshKey,
        onRefresh: context.read<ExplorerController>().refresh,
      );
    }
    final viewType = context.watch<FolderViewNotifier>().folderViewType;
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: context.read<ExplorerController>().refresh,
      child: switch (viewType) {
        FolderViewType.list => FolderListView(node: widget._explorerFocusNode),
        FolderViewType.gridSmall => const FolderGridView(itemWidth: 160),
        FolderViewType.gridLarge => const FolderGridView(itemWidth: 240),
      },
    );
  }
}

class SelectedResourceView extends StatefulWidget {
  final Iterable<Resource> resources;

  const SelectedResourceView({super.key, required this.resources});

  @override
  State<SelectedResourceView> createState() => _SelectedResourceViewState();
}

class _SelectedResourceViewState extends State<SelectedResourceView> {
  final _selectedResourcesOptionsButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: IconButtonTheme(
        data: IconButtonThemeData(
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(6),
            iconSize: 20.0,
            minimumSize: Size.zero,
          ),
        ),
        child: Row(
          spacing: 16.0,
          children: [
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                context.read<ExplorerController>().clearSelection();
              },
            ),
            Text(
              '${widget.resources.length} selected',
              style: TextStyle(fontSize: 15),
            ),
            IconButton(
              key: _selectedResourcesOptionsButtonKey,
              onPressed: () async {
                final state = context.read<ExplorerState>();
                final resources = state.selected;
                final renderBox =
                    _selectedResourcesOptionsButtonKey.currentContext
                            ?.findRenderObject()
                        as RenderBox?;

                final height = renderBox?.size.height ?? 0.0;

                final position =
                    renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;

                final groups = await getEnabledOptions(
                  context.read(),
                  state.location.selectedResourceOptions,
                  resources,
                );

                if (!context.mounted) return;
                ContextMenuHelper.show(
                  context: context,
                  position: position.translate(0, height),
                  groups: groups,
                  onOptionSelected: (option) {
                    if (context.mounted) {
                      handleOption(context, resources, option);
                    }
                  },
                );
              },
              icon: Icon(Icons.adaptive.more),
            ),
          ],
        ),
      ),
    );
  }
}
