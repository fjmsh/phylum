import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/time.dart';
import 'package:provider/provider.dart';

import 'resource_icon_extension.dart';

class ResourceInfoView extends StatelessWidget {
  final String folderId;

  const ResourceInfoView({super.key, required this.folderId});

  @override
  Widget build(BuildContext context) {
    final resource = context.select<ExplorerViewState, Resource?>((state) {
      return state.focussedIfSelected ?? state.folder;
    });

    if (resource == null) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    return ListView(
      children: [
        ListTile(
          leading: resource.getIcon(),
          title: Text(resource.name, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: const Text('Type'),
          subtitle: Text(resource.dir ? 'Folder' : resource.contentType),
        ),
        ListTile(
          title: const Text('Created'),
          subtitle: Text(resource.created?.formatReadable() ?? '--'),
        ),
        ListTile(
          title: const Text('Modified'),
          subtitle: Text(resource.modified?.formatReadable() ?? '--'),
        ),
        if (!resource.dir)
          ListTile(
            title: const Text('Size'),
            subtitle: Text(resource.contentSize.getHumanString()),
          ),
        if (!resource.dir)
          ListTile(
            title: const Text('SHA-256'),
            subtitle: Text(resource.contentSha256),
          ),
      ],
    );
  }
}
