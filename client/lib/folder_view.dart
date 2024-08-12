import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/resource_detail_request.dart';
import 'package:provider/provider.dart';

class FolderView extends StatefulWidget {
  final String id;

  const FolderView({super.key, required this.id});

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

    return RefreshIndicator(
      onRefresh: _refresh,
      child: Center(
        child: StreamBuilder(
            stream: account.datastore.db.managers.resources.filter((f) => f.parent.id.equals(widget.id)).watch(),
            builder: (context, snapshot) {
              return Column(
                children: [
                  if (snapshot.hasData)
                    for (final r in snapshot.data!)
                      ListTile(
                        leading: r.getIcon(),
                        title: Text(r.name),
                        trailing: r.dir ? null : Text(r.getSizeString()),
                        onTap: () => context.go('/dir/${r.id}'),
                      ),
                ],
              );
            }),
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
