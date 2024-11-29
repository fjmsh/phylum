import 'dart:async';

import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_share.dart';
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
  late String resourceName;
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
        resourceName = data.last.name;
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

    final account = context.read<PhylumAccount>();
    final repository = account.userRepository;
    final userPermissions = permissions[account.userName] ?? 0;
    final entries = permissions.entries.toList(growable: false)
      ..sort(((a, b) {
        return a.value == b.value ? a.key.compareTo(b.key) : a.value.compareTo(b.value);
      }));
    return DropdownButtonHideUnderline(
      child: Column(
        children: [
          for (final e in entries)
            ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              title: Text(repository.getUserDisplayName(e.key)),
              trailing: DropdownButton<Permission>(
                items: _createPermissionsItems(),
                value: e.value,
                onChanged: (userPermissions & permissionShare) == 0
                    ? null
                    : (value) {
                        if (value == null) return;
                        account.addAction(ResourceShareAction(
                          resourceId: widget.resourceId,
                          resourceName: resourceName,
                          username: e.key,
                          permission: value,
                        ));
                      },
              ),
              // trailing: _getPermissionIcon(e.value),
            ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<Permission>> _createPermissionsItems() {
    return [
      _buildDropdownMenuItem(permissionSetNone),
      _buildDropdownMenuItem(permissionSetReadOnly),
      _buildDropdownMenuItem(permissionSetReadWrite),
      _buildDropdownMenuItem(permissionSetReadWriteShare),
      _buildDropdownMenuItem(permissionSetAll),
    ];
  }

  DropdownMenuItem<Permission> _buildDropdownMenuItem(Permission p) {
    return DropdownMenuItem(value: p, child: _buildTile(p));
  }

  Widget _buildTile(Permission p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: _getIcon(p),
        ),
        Text(_getText(p)),
      ],
    );
  }

  Icon _getIcon(Permission p) {
    if (p == 0) return const Icon(Icons.block);
    if (p == -1) return const Icon(Icons.shield_outlined);
    if (p == permissionSetReadOnly) return const Icon(Icons.visibility);
    if (p == permissionSetReadWrite) return const Icon(Icons.edit);
    if (p == permissionSetReadWriteShare) return const Icon(Icons.person_add);
    return const Icon(Icons.settings);
  }

  String _getText(Permission p) {
    if (p == 0) return 'None';
    if (p == -1) return 'Admin';
    if (p == permissionSetReadOnly) return 'Viewer';
    if (p == permissionSetReadWrite) return 'Collaborator';
    if (p == permissionSetReadWriteShare) return 'Editor';
    return 'Custom';
  }
}
