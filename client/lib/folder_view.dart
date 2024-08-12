import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:provider/provider.dart';

class FolderNavigatorState {
  final String root;
  final List<String> _stack;

  bool get isRoot => _stack.isEmpty;

  String get folderId => isRoot ? root : _stack.last;

  const FolderNavigatorState({required this.root, required List<String> stack}) : _stack = stack;
}

class FolderNavigator extends StateNotifier<FolderNavigatorState> {
  final String root;

  FolderNavigator(this.root) : super(FolderNavigatorState(root: root, stack: const []));

  bool pop() {
    if (state.isRoot) return false;
    state = FolderNavigatorState(root: state.root, stack: state._stack.sublist(0, state._stack.length - 1).toList(growable: false));
    return true;
  }

  void push(String id) {
    state = FolderNavigatorState(root: state.root, stack: [...state._stack, id]);
  }
}

class FolderNavigatorView extends StatelessWidget {
  final String root;

  const FolderNavigatorView({super.key, required this.root});

  @override
  Widget build(BuildContext context) {
    return StateNotifierProvider<FolderNavigator, FolderNavigatorState>(
      create: (context) => FolderNavigator(root),
      builder: (context, child) => const FolderScaffold(),
    );
  }
}

class FolderScaffold extends StatelessWidget {
  const FolderScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<FolderNavigatorState>();
    final folderId = nav.folderId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phylum'),
        leading: nav.isRoot ? null : BackButton(onPressed: context.read<FolderNavigator>().pop),
      ),
      body: FolderContentsView(key: ValueKey(folderId), id: folderId),
    );
  }
}

class FolderContentsView extends StatefulWidget {
  final String id;

  const FolderContentsView({super.key, required this.id});

  @override
  State<FolderContentsView> createState() => _FolderContentsViewState();
}

class _FolderContentsViewState extends State<FolderContentsView> {
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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Center(
        child: StreamBuilder(
            stream: account.datastore.db.managers.resources.filter((f) => f.parent.id.equals(widget.id)).watch(),
            builder: (context, snapshot) => ListView(
                  children: [
                    if (snapshot.hasData)
                      for (final r in snapshot.data!)
                        ListTile(
                          leading: r.getIcon(),
                          title: Text(r.name),
                          trailing: r.dir ? null : Text(r.getSizeString()),
                          onTap: () => context.read<FolderNavigator>().push('/dir/${r.id}'),
                        ),
                  ],
                )),
      ),
    );
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

  String getSizeString() {
    const suffixes = ['B', 'K', 'M', 'G'];
    var sz = size;
    for (var i = 0; i < suffixes.length; i++) {
      if (sz < 1000) {
        return '$sz ${suffixes[i]}';
      }
      sz ~/= 1024;
    }
    return '$sz T';
  }
}
