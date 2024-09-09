import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/app_shortcuts.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/folder/folder_contents_view.dart';
import 'package:phylum/ui/folder/folder_navigator_stack.dart';
import 'package:phylum/ui/folder/folder_selection_manager.dart';
import 'package:provider/provider.dart';

class FolderView extends StatefulWidget {
  final String id;

  FolderView({required this.id}) : super(key: ValueKey(id));

  @override
  State<FolderView> createState() => _FolderViewState();
}

class _FolderViewState extends State<FolderView> {
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future _refresh() {
    debugPrint('Requesting ${widget.id}');
    return context.read<PhylumAccount>().resourceRepository.requestResource(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
    final theme = Theme.of(context);

    return Actions(
      actions: {
        NextFocusIntent: CallbackAction<NextFocusIntent>(onInvoke: (i) => null),
        PreviousFocusIntent: CallbackAction<PreviousFocusIntent>(onInvoke: (i) => null),
        NavUpIntent: CallbackAction<NavUpIntent>(onInvoke: (i) {
          context.read<FolderNavigatorStack>().pop();
          return null;
        }),
      },
      child: ListTileTheme(
        data: ListTileThemeData(
          mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.basic),
          selectedTileColor: theme.colorScheme.primaryContainer,
        ),
        child: StateNotifierProvider<FolderSelectionManager, FolderSelectionState>(
          create: (context) => FolderSelectionManager(),
          child: StreamBuilder(
              stream: account.resourceRepository.watchResource(widget.id),
              builder: (context, snapshot) {
                final folder = snapshot.data;
                if (folder?.lastFetch == null) {
                  return buildEmptyView('Loading');
                }
                return StreamBuilder(
                    stream: account.resourceRepository.watchChildren(widget.id),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container();
                      }
                      if (snapshot.data!.isEmpty) {
                        return buildEmptyView('Nothing here');
                      }
                      return RefreshIndicator(
                          onRefresh: _refresh,
                          child: FolderContentsView(
                            folderId: widget.id,
                            resources: snapshot.data!,
                          ));
                    });
              }),
        ),
      ),
    );
  }

  Widget buildEmptyView(String text) {
    return Focus(
      autofocus: true,
      child: LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
          onRefresh: _refresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Center(child: Text(text)),
            ),
          ),
        ),
      ),
    );
  }
}
