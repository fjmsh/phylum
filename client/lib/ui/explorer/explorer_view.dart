import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/ui/explorer/explorer_actions.dart';
import 'package:phylum/ui/explorer/explorer_gesture_handler.dart';
import 'package:phylum/ui/explorer/path_view.dart';
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
      print('Received files when in memory');
      print(files);
      ReceiveSharingIntent.instance.reset();
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance.getInitialMedia().then((value) {
      final files = value.map((f) => f.path).toList(growable: false);
      print('Received files when closed');
      print(files);
      ReceiveSharingIntent.instance.reset();
    });
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
