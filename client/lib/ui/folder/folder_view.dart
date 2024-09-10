import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/app/app_layout.dart';
import 'package:phylum/ui/folder/folder_contents_view.dart';
import 'package:phylum/ui/folder/folder_empty_view.dart';
import 'package:phylum/ui/folder/folder_selection_manager.dart';
import 'package:provider/provider.dart';

class FolderView extends StatelessWidget {
  const FolderView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StateNotifierProvider<FolderSelectionManager, FolderSelectionState>(
      create: (context) => FolderSelectionManager(),
      child: Actions(
        actions: {
          NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
          PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
        },
        child: ListTileTheme(
          data: ListTileThemeData(
            mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.basic),
            selectedTileColor: theme.colorScheme.primaryContainer,
          ),
          child: const FolderWatcher(),
        ),
      ),
    );
  }
}

class FolderWatcher extends StatelessWidget {
  const FolderWatcher({super.key});

  @override
  Widget build(BuildContext context) => FolderContentsListener(id: context.watch<CurrentLocation>().folderId);
}

class FolderContentsListener extends StatefulWidget {
  final String id;

  FolderContentsListener({required this.id}) : super(key: ValueKey(id));

  @override
  State<FolderContentsListener> createState() => _FolderContentsListenerState();
}

class _FolderContentsListenerState extends State<FolderContentsListener> {
  Resource? resource;
  List<Resource> children = const [];
  StreamSubscription<Resource?>? resourceSubscription;
  StreamSubscription<List<Resource>>? childrenSubscription;

  @override
  void initState() {
    super.initState();
    _refresh();
    final account = context.read<PhylumAccount>();
    resourceSubscription = account.resourceRepository.watchResource(widget.id).listen((e) => setState(() => resource = e));
    childrenSubscription = account.resourceRepository.watchChildren(widget.id).listen((e) => setState(() => children = e));
  }

  @override
  void dispose() {
    super.dispose();
    resourceSubscription?.cancel();
    childrenSubscription?.cancel();
  }

  Future _refresh() {
    return context.read<PhylumAccount>().resourceRepository.requestResource(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      if (resource?.lastFetch == null) {
        return FolderEmptyView(type: FolderEmptyViewType.loading, onRefresh: _refresh);
      }
      return FolderEmptyView(type: FolderEmptyViewType.noData, onRefresh: _refresh);
    }
    return RefreshIndicator(
        onRefresh: _refresh,
        child: FolderContentsView(
          folderId: widget.id,
          resources: children,
        ));
  }
}
