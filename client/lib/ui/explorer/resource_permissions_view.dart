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
  User? selectedUser;
  Permission selectedUserPermission = permissionSetNone;
  Map<String, Permission>? inheritedPermissions;
  Map<String, Permission>? permissions;

  StreamSubscription<List<ParentsResult>>? sub;
  @override
  void initState() {
    super.initState();
    final account = context.read<PhylumAccount>();
    sub = account.resourceRepository.watchParents(widget.resourceId).listen((data) {
      final inheritedPermissions = calculatePermissionSet(data.sublist(1).map((e) => e.permissions));
      final permissions = mergePermissions(Map.of(inheritedPermissions), data.first.permissions);
      setState(() {
        resourceName = data.first.name;
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
    final inheritedPermissions = this.inheritedPermissions;
    if (permissions == null || inheritedPermissions == null) return const CircularProgressIndicator();

    final account = context.read<PhylumAccount>();
    final repository = account.userRepository;
    final userPermissions = permissions[account.userName] ?? 0;
    final entries = permissions.entries.toList(growable: false)
      ..sort(((a, b) {
        return a.value == b.value ? a.key.compareTo(b.key) : a.value.compareTo(b.value);
      }));
    final theme = Theme.of(context);
    if (selectedUser != null) {
      return DropdownButtonHideUnderline(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Chip(
              label: Text(selectedUser!.display),
              deleteIcon: Icon(Icons.cancel_rounded),
              onDeleted: () => setState(() => selectedUser = null),
            ),
            DropdownButton<Permission>(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              items: _createPermissionsItems(theme, selectedUserPermission, 0),
              value: selectedUserPermission,
              onChanged: (userPermissions & permissionShare) == 0 ? null : (value) => setState(() => selectedUserPermission = value!),
            ),
          ],
        ),
      );
    }
    return DropdownButtonHideUnderline(
      child: Column(
        children: [
          if (userPermissions & permissionShare != 0)
            Autocomplete<User>(
              fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onSubmitted: (value) => onFieldSubmitted,
                  decoration: InputDecoration(
                    hintText: 'Add User',
                    border: OutlineInputBorder(),
                  ),
                );
              },
              optionsBuilder: (value) {
                final query = value.text.toLowerCase().trim();
                return query.isEmpty
                    ? const []
                    : account.userRepository.users.entries
                        .where((e) =>
                            !inheritedPermissions.containsKey(e.key) &&
                            !permissions.containsKey(e.key) &&
                            (e.key.toLowerCase().contains(query) || e.value.display.toLowerCase().contains(query)))
                        .map((e) => e.value);
              },
              displayStringForOption: (option) => option.display,
              onSelected: (user) {
                setState(() {
                  selectedUser = user;
                  selectedUserPermission = permissionSetReadOnly;
                });
              },
            ),
          for (final e in entries)
            ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              title: Text(repository.getUserDisplayName(e.key)),
              trailing: DropdownButton<Permission>(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                items: _createPermissionsItems(theme, e.value, inheritedPermissions[e.key] ?? 0),
                value: e.value,
                onChanged: (userPermissions & permissionShare) == 0
                    ? null
                    : (value) {
                        if (value == null || value == e.value) return;
                        if (value == inheritedPermissions[e.key]) {
                          value = 0;
                        }
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

  List<DropdownMenuItem<Permission>> _createPermissionsItems(ThemeData theme, Permission p, Permission inherited) {
    return [
      _buildDropdownMenuItem(permissionSetNone, inherited, theme),
      _buildDropdownMenuItem(permissionSetReadOnly, inherited, theme),
      _buildDropdownMenuItem(permissionSetReadWrite, inherited, theme),
      _buildDropdownMenuItem(permissionSetReadWriteShare, inherited, theme),
      if (p == permissionSetAll) _buildDropdownMenuItem(permissionSetAll, inherited, theme),
      if (p != permissionSetNone &&
          p != permissionSetReadOnly &&
          p != permissionSetReadWrite &&
          p != permissionSetReadWriteShare &&
          p != permissionSetAll)
        _buildDropdownMenuItem(p, inherited, theme),
    ];
  }

  DropdownMenuItem<Permission> _buildDropdownMenuItem(Permission p, Permission inherited, ThemeData theme) {
    bool enabled = (p | inherited) == p || (p | inherited) != inherited;

    final iconColor = enabled ? theme.listTileTheme.iconColor : theme.disabledColor;
    final textColor = enabled ? theme.listTileTheme.tileColor : theme.disabledColor;

    return DropdownMenuItem(
      value: p,
      enabled: enabled,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(_getIcon(p), color: iconColor),
          ),
          Text(
            _getText(p),
            style: TextStyle(color: textColor),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(Permission p) {
    if (p == 0) return Icons.block;
    if (p == -1) return Icons.shield_outlined;
    if (p == permissionSetReadOnly) return Icons.visibility;
    if (p == permissionSetReadWrite) return Icons.edit;
    if (p == permissionSetReadWriteShare) return Icons.person_add;
    return Icons.settings;
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
