import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_delete.dart';
import 'package:phylum/libphylum/actions/action_resource_rename.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:phylum/ui/folder/resource_options_dialog.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

import 'folder_navigator_stack.dart';

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
            stream: account.datastore.db.managers.resources.filter((f) => f.parent.id.equals(widget.id) & f.deleted.equals(false)).watch(),
            builder: (context, snapshot) => ListView(
                  children: [
                    if (snapshot.hasData)
                      for (final r in snapshot.data!)
                        ListTile(
                          leading: r.getIcon(),
                          title: Text(r.name),
                          subtitle: r.dir ? const Text('Folder') : Text(r.getSizeString()),
                          trailing: IconButton(icon: Icon(Icons.adaptive.more), onPressed: () => showResourceOptions(account, r)),
                          onTap: r.dir ? () => context.read<FolderNavigatorStack>().push(r.id) : null,
                          onLongPress: () => showResourceOptions(account, r),
                        ),
                  ],
                )),
      ),
    );
  }

  void showResourceOptions(PhylumAccount account, Resource r) async {
    final context = this.context;
    final option = await showModalBottomSheet(context: context, builder: (context) => const ResourceOptionsList());
    if (!context.mounted) {
      return;
    }
    switch (option) {
      case ResourceOption.rename:
        final name = await showInputDialog(context, title: 'Rename', preset: r.name);
        if (name != null) {
          account.api.sendRequest(ResourceRenameAction(r: r, name: name));
        }
      case ResourceOption.delete:
        final confirm = await showAlertDialog(context, title: 'Delete ${r.name}?', positiveText: 'YES', negativeText: 'NO') ?? false;
        if (confirm) {
          account.api.sendRequest(ResourceDeleteAction(r: r));
        }
    }
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
