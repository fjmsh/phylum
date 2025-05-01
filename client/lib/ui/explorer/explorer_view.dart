import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/libphylum/name_conflict.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/destination_picker/destination_picker.dart';
import 'package:phylum/ui/explorer/explorer_actions.dart';
import 'package:phylum/ui/explorer/explorer_gesture_handler.dart';
import 'package:phylum/ui/explorer/path_view.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/upload_utils.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'explorer_controller.dart';
import 'folder_empty_view.dart';
import 'folder_list_view.dart';

class ExplorerView extends StatefulWidget {
  final bool small;

  const ExplorerView({super.key, required this.small});

  @override
  State<ExplorerView> createState() => _ExplorerViewState();
}

class _ExplorerViewState extends State<ExplorerView> {
  final _refreshKey = GlobalKey<RefreshIndicatorState>();
  late StreamSubscription _intentSub;

  @override
  void initState() {
    super.initState();

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((value) {
      final files = value.map((f) => f.path).toList(growable: false);
      handleShareIntent(files).then((value) => ReceiveSharingIntent.instance.reset());
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      final files = value.map((f) => f.path).toList(growable: false);
      handleShareIntent(files).then((value) => ReceiveSharingIntent.instance.reset());
    });
  }

  Future<void> handleShareIntent(List<String> paths) async {
    final account = context.read<PhylumAccount>();
    final dest = await DestinationPicker.show(context, account.userHome, allowInitialFolder: true);
    if (dest == null) {
      return;
    }
    if (!context.mounted) return;
    for (final path in paths) {
      if (!mounted) return;
      final name = await showInputDialog(context, hintText: 'File name', preset: p.basename(path));
      if (!mounted || name == null) return;
      await handleNameConflict(
        context,
        name,
        overwriteFn: (r) => r.dir ? nameConflictDelete : nameConflictOverwrite,
        (name, conflictResolution) => account.resourceRepository.upload(
          parent: dest,
          name: name,
          path: path,
          conflictResolution: conflictResolution,
        ),
      );
    }
  }

  @override
  void dispose() {
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExplorerActions(
      refreshKey: _refreshKey,
      child: ExplorerGestureHandler(
        child: Column(
          children: [
            PathView(small: widget.small),
            Expanded(child: buildPage(context)),
          ],
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
    return RefreshIndicator(
      key: _refreshKey,
      onRefresh: context.read<ExplorerController>().refresh,
      child: const FolderListView(),
    );
  }
}
