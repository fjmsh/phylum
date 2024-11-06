import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/explorer/explorer_view_controller.dart';
import 'package:phylum/util/file_size.dart';
import 'package:phylum/util/permissions.dart';
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
        PermissionsTile(resourceId: resource.id),
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

class PermissionsTile extends StatefulWidget {
  final String resourceId;

  PermissionsTile({required this.resourceId}) : super(key: ValueKey(resourceId));

  @override
  State<PermissionsTile> createState() => _PermissionsTileState();
}

class _PermissionsTileState extends State<PermissionsTile> {
  Permission? myPermission;
  Map<String, Permission>? otherPermissions;

  StreamSubscription<List<ParentsResult>>? sub;
  @override
  void initState() {
    super.initState();
    final account = context.read<PhylumAccount>();
    sub = account.db.parents(widget.resourceId).watch().listen((data) {
      final p = calculatePermissionSet(data.map((e) => e.permissions));
      setState(() {
        myPermission = p.remove(account.userEmail) ?? 0;
        otherPermissions = p;
      });
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = otherPermissions?.entries.toList(growable: false)?..sort(((a, b) => a.key.compareTo(b.key)));
    final other = entries?.map((e) => '${e.key}: ${e.value.toStringShort()}').join(', ');
    return Column(
      children: [
        ListTile(
          title: const Text('My Permissions'),
          subtitle: myPermission == null ? const Text('') : Text(myPermission!.toStringFull()),
        ),
        ListTile(
          title: const Text('Others with Access'),
          subtitle: other == null ? const Text('') : Text(other),
        ),
      ],
    );
  }
}
