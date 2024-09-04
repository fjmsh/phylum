import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:phylum/ui/folder/folder_contents_view.dart';
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

  Future<void> _refresh() async {
    await context.read<PhylumAccount>().api.sendRequest(ResourceDetailRequest(widget.id));
  }

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();

    return Focus(
      onKeyEvent: (node, event) {
        if (event.logicalKey == LogicalKeyboardKey.tab) {
          return KeyEventResult.skipRemainingHandlers;
        }
        return KeyEventResult.ignored;
      },
      child: ListTileTheme(
        data: const ListTileThemeData(mouseCursor: WidgetStatePropertyAll(SystemMouseCursors.basic)),
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: StateNotifierProvider<FolderSelectionManager, FolderSelectionState>(
            create: (context) => FolderSelectionManager(),
            child: StreamBuilder(
                stream: account.datastore.db.managers.resources
                    .filter((f) => f.parent.id.equals(widget.id) & f.deleted.equals(false))
                    .orderBy((o) => o.dir.desc())
                    .orderBy((o) => o.name.asc())
                    .watch(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container();
                  }
                  return FolderContentsView(resources: snapshot.data!);
                }),
          ),
        ),
      ),
    );
  }
}
