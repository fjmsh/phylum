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
  Map<String, Permission>? inheritedPermissions;
  Map<String, Permission>? permissions;

  StreamSubscription<List<ParentsResult>>? sub;
  @override
  void initState() {
    super.initState();
    final account = context.read<PhylumAccount>();
    sub = account.db.parents(widget.resourceId).watch().listen((data) {
      final inheritedPermissions = calculatePermissionSet(data.sublist(0, data.length - 1).map((e) => e.permissions));
      final permissions = mergePermissions(Map.of(inheritedPermissions), data.last.permissions);
      setState(() {
        this.inheritedPermissions = inheritedPermissions;
        this.permissions = permissions;
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
    final permissions = this.permissions;
    if (permissions == null) return const CircularProgressIndicator();

    final repository = context.read<PhylumAccount>().userRepository;
    final entries = permissions.entries.toList(growable: false)
      ..sort(((a, b) {
        return a.value == b.value ? a.key.compareTo(b.key) : a.value.compareTo(b.value);
      }));
    return Column(
      children: [
        for (final e in entries)
          ListTile(
            title: Text(repository.getUserDisplayName(e.key)),
            trailing: _getPermissionIcon(e.value),
          ),
      ],
    );
  }

  Icon? _getPermissionIcon(Permission p) {
    if (p == 0) return null;
    if (p == -1) return const Icon(Icons.shield_outlined);
    if (p == permissionRead) return const Icon(Icons.visibility);
    if (p == (permissionRead | permissionWrite)) return const Icon(Icons.edit);
    if (p == (permissionRead | permissionWrite | permissionShare)) return const Icon(Icons.person_add);
    return const Icon(Icons.settings);
  }
}
