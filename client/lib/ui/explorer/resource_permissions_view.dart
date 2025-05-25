import 'dart:async';

import 'package:drift/drift.dart' show TableOrViewStatements;
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_share.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/permissions.dart';
import 'package:provider/provider.dart';

class ResourcePermissionsView extends StatefulWidget {
  final String resourceId;

  ResourcePermissionsView({required this.resourceId}) : super(key: ValueKey(resourceId));

  @override
  State<ResourcePermissionsView> createState() => _ResourcePermissionsViewState();
}

class _ResourcePermissionsViewState extends State<ResourcePermissionsView> {
  String? resourceName;
  Map<int, Permission>? permissions;
  Map<int, Permission>? grants;
  Permission? userPermission;

  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    final account = context.read<PhylumAccount>();
    sub = account.db.watchPermissions(widget.resourceId).listen((data) {
      setState(() {
        resourceName = data?.name;
        userPermission = data?.userPermission;
        permissions = data?.inheritedPermissions.parsePermissionMap();
        grants = data?.grants.parsePermissionMap();
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
    final grants = this.grants;
    final permissions = this.permissions;
    if (grants == null || permissions == null) return const CircularProgressIndicator();

    final account = context.read<PhylumAccount>();
    final repository = account.userRepository;
    final grantEntries = grants.entries.toList(growable: false)
      ..sort(((a, b) {
        return a.value == b.value ? a.key.compareTo(b.key) : a.value.compareTo(b.value);
      }));
    final permissionEntries = permissions.entries.toList(growable: false)
      ..sort(((a, b) {
        return a.value == b.value ? a.key.compareTo(b.key) : a.value.compareTo(b.value);
      }));
    final theme = Theme.of(context);
    return DropdownButtonHideUnderline(
      child: Column(
        children: [
          if (userPermission! & permissionShare != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ElevatedButton.icon(
                label: Text('Add User'),
                icon: Icon(Icons.person_add),
                onPressed: () async {
                  final users =
                      account.userRepository.users.entries.where((e) => !grants.containsKey(e.key)).map((e) => e.value);
                  final user = await showOptionsDialogBuilder(
                    context,
                    users.toList(growable: false),
                    (user) => ListTile(title: Text(repository.getUserDisplayName(user.id))),
                    filterList: (u, q) {
                      final query = q.toLowerCase();
                      return u
                          .where((u) => u.email.contains(query) || u.displayName.contains(query))
                          .toList(growable: false);
                    },
                  );
                  if (user == null || !context.mounted) return;
                  final permission = await showOptionsDialogBuilder(
                    context,
                    [
                      permissionSetReadOnly,
                      permissionSetReadWrite,
                      permissionSetReadWriteShare,
                    ],
                    (p) => ListTile(leading: Icon(p.icon), title: Text(p.text)),
                  );
                  if (permission == null || !context.mounted) return;
                  account.addAction(ResourceShareAction(
                    resourceId: widget.resourceId,
                    resourceName: resourceName!,
                    user: user,
                    permission: permission,
                  ));
                },
              ),
            ),
          for (final e in grantEntries)
            ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              title: Text(repository.getUserDisplayName(e.key)),
              trailing: DropdownButton<Permission>(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                items: _createPermissionsItems(theme, e.value),
                value: e.value,
                onChanged: (userPermission! & permissionShare) == 0
                    ? null
                    : (value) async {
                        if (value == null || value == e.value) return;
                        if (value == permissions[e.key]) {
                          value = 0;
                        }
                        final user =
                            await (account.db.users.select()..where((u) => u.id.equals(e.key))).getSingleOrNull();
                        if (user == null) return;

                        account.addAction(ResourceShareAction(
                          resourceId: widget.resourceId,
                          resourceName: resourceName!,
                          user: user,
                          permission: value,
                        ));
                      },
              ),
            ),
          ListTile(
            visualDensity: VisualDensity.compact,
            dense: true,
            title: const Text('Inherited Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          for (final e in permissionEntries)
            ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              leading: Icon(e.value.icon),
              title: Text(repository.getUserDisplayName(e.key)),
              subtitle: Text(e.value.text),
            ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<Permission>> _createPermissionsItems(ThemeData theme, Permission p) {
    return [
      _buildDropdownMenuItem(permissionSetNone, theme),
      _buildDropdownMenuItem(permissionSetReadOnly, theme),
      _buildDropdownMenuItem(permissionSetReadWrite, theme),
      _buildDropdownMenuItem(permissionSetReadWriteShare, theme),
      if (p == permissionSetAll) _buildDropdownMenuItem(permissionSetAll, theme),
      if (p != permissionSetNone &&
          p != permissionSetReadOnly &&
          p != permissionSetReadWrite &&
          p != permissionSetReadWriteShare &&
          p != permissionSetAll)
        _buildDropdownMenuItem(p, theme),
    ];
  }

  DropdownMenuItem<Permission> _buildDropdownMenuItem(Permission p, ThemeData theme) {
    final iconColor = theme.listTileTheme.iconColor;
    final textColor = theme.listTileTheme.tileColor;

    return DropdownMenuItem(
      value: p,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(p.icon, color: iconColor),
          ),
          Text(
            p.text,
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }
}

extension on Permission {
  IconData get icon {
    if (this == 0) return Icons.block;
    if (this == -1) return Icons.shield_outlined;
    if (this == permissionSetReadOnly) return Icons.visibility;
    if (this == permissionSetReadWrite) return Icons.edit;
    if (this == permissionSetReadWriteShare) return Icons.person_add;
    return Icons.settings;
  }

  String get text {
    if (this == 0) return 'None';
    if (this == -1) return 'Admin';
    if (this == permissionSetReadOnly) return 'Viewer';
    if (this == permissionSetReadWrite) return 'Collaborator';
    if (this == permissionSetReadWriteShare) return 'Editor';
    return 'Custom';
  }
}
