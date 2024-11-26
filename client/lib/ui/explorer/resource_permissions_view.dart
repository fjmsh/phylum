import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/permissions.dart';
import 'package:provider/provider.dart';

class ResourcePermissionsView extends StatefulWidget {
  final String resourceId;

  ResourcePermissionsView({required this.resourceId}) : super(key: ValueKey(resourceId));

  @override
  State<ResourcePermissionsView> createState() => _ResourcePermissionsViewState();
}

class _ResourcePermissionsViewState extends State<ResourcePermissionsView> {
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
    final otherPermissions = this.otherPermissions;
    if (otherPermissions == null) return const CircularProgressIndicator();
    final repository = context.read<PhylumAccount>().userRepository;
    final entries = otherPermissions.entries.toList(growable: false)..sort(((a, b) => a.key.compareTo(b.key)));
    // final other = entries?.map((e) => '${repository.getUserDisplayName(e.key)}: ${e.value.toStringShort()}').join(', ');
    return Column(
      children: [
        ListTile(
          title: Text(repository.getUserDisplayName(context.read<PhylumAccount>().userName)),
          trailing: Text(myPermission?.toStringFull() ?? ''),
        ),
        for (final e in entries)
          ListTile(
            title: Text(repository.getUserDisplayName(e.key)),
            trailing: Text(e.value.toStringFull()),
          ),
      ],
    );
  }
}
