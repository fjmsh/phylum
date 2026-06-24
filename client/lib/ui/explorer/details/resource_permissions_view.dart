import 'dart:async';

import 'package:drift/drift.dart' show TableOrViewStatements;
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_share.dart';
import 'package:phylum/libphylum/db/resource_helpers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:phylum/ui/common/new_user_details_dialog.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/logging/logging.dart';
import 'package:phylum/util/permissions.dart';
import 'package:phylum/util/user_display_name.dart';
import 'package:provider/provider.dart';

class ResourcePermissionsView extends StatefulWidget {
  final String resourceId;

  ResourcePermissionsView({required this.resourceId})
    : super(key: ValueKey(resourceId));

  @override
  State<ResourcePermissionsView> createState() =>
      _ResourcePermissionsViewState();
}

class _ResourcePermissionsViewState extends State<ResourcePermissionsView> {
  String? resourceName;
  Map<int, Permission>? permissions;
  Map<int, Permission>? grants;
  late Permission userPermission;

  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    final account = context.read<PhylumAccount>();
    userPermission = account.user.filesPermissions;
    sub = account.db.watchPermissions(widget.resourceId).listen((data) {
      if (data == null) return;
      setState(() {
        resourceName = data.name;
        userPermission = account.user.filesPermissions | data.userPermission;
        permissions = data.inheritedPermissions.parsePermissionMap();
        grants = data.grants.parsePermissionMap();
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
    if (grants == null || permissions == null) {
      return const CircularProgressIndicator();
    }

    final account = context.read<PhylumAccount>();
    final repository = account.userRepository;
    final grantEntries = grants.entries.toList(growable: false)
      ..sort(((a, b) {
        return a.value == b.value
            ? a.key.compareTo(b.key)
            : a.value.compareTo(b.value);
      }));
    final permissionEntries = permissions.entries.toList(growable: false)
      ..sort(((a, b) {
        return a.value == b.value
            ? a.key.compareTo(b.key)
            : a.value.compareTo(b.value);
      }));
    return DropdownButtonHideUnderline(
      child: Column(
        children: [
          if (userPermission & permissionShare != 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ElevatedButton.icon(
                label: Text('Grant Access'),
                icon: Icon(Icons.person_add),
                onPressed: () => addUser(context),
              ),
            ),
          for (final e in grantEntries)
            ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              leading: Icon(e.value.icon),
              title: Text(repository.getUserDisplayName(e.key)),
              subtitle: Text(e.value.text),
              trailing: IconButton(
                onPressed: () async {
                  final permission = permissionSetNone;
                  final user =
                      await (account.db.users.select()
                            ..where((u) => u.id.equals(e.key)))
                          .getSingleOrNull();
                  Log.warn('User not found: ${e.key}');
                  if (user == null) return;

                  account.addAction(
                    ResourceShareAction(
                      resourceId: widget.resourceId,
                      resourceName: resourceName!,
                      user: user,
                      permission: permission,
                    ),
                  );
                },
                icon: Icon(Icons.close),
              ),
              onTap: (userPermission & permissionShare) == 0
                  ? null
                  : () async {
                      final permission = await _showPermissionsPicker(context);
                      if (permission == null || permission == e.value) return;
                      final user =
                          await (account.db.users.select()
                                ..where((u) => u.id.equals(e.key)))
                              .getSingleOrNull();
                      if (user == null) return;

                      account.addAction(
                        ResourceShareAction(
                          resourceId: widget.resourceId,
                          resourceName: resourceName!,
                          user: user,
                          permission: permission,
                        ),
                      );
                    },
            ),
          ListTile(
            key: ValueKey('inherited'),
            visualDensity: VisualDensity.compact,
            dense: true,
            title: const Text(
              'Inherited Permissions',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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

  Future<void> addUser(BuildContext context) async {
    final account = context.read<PhylumAccount>();
    final allUsers =
        await (account.db.users.select()
              ..where((u) => u.id.isNotIn(grants!.keys)))
            .get();
    final users = allUsers.toList(growable: false)
      ..sort((a, b) {
        // TODO: not the most efficient
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });
    if (!context.mounted) return;
    final user = await showOptionsDialogBuilder(
      context,
      users,
      (user) => user.displayName.isEmpty
          ? ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              title: Text(
                user.email,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          : ListTile(
              visualDensity: VisualDensity.adaptivePlatformDensity,
              title: Text(user.displayName),
              subtitle: Text(user.email),
            ),
      buildLastItem:
          account.config.mail.enabled &&
              (account.config.allowInvites ||
                  account.user.hasPermission(userPermissionUsersCreateInvite))
          ? (_) => ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Invite'),
              onTap: () async {
                final navigator = Navigator.of(context);
                await inviteUser(context);
                navigator.pop();
              },
            )
          : null,
      filterList: (u, q) {
        final query = q.toLowerCase();
        return u
            .where((u) => u.email.contains(query) || u.name.contains(query))
            .toList(growable: false);
      },
    );
    if (user == null || !context.mounted) return;
    final permission = await _showPermissionsPicker(context);
    if (permission == null || !context.mounted) return;
    account.addAction(
      ResourceShareAction(
        resourceId: widget.resourceId,
        resourceName: resourceName!,
        user: user,
        permission: permission,
      ),
    );
  }

  Future<void> inviteUser(BuildContext context) async {
    final userDetails = await NewUserDetailsDialog.show(context);
    if (userDetails == null || !context.mounted) return;
    final permission = await _showPermissionsPicker(context);
    if (permission == null || !context.mounted) return;

    final account = context.read<PhylumAccount>();
    final user = await account.userRepository.invite(
      email: userDetails.email,
      name: userDetails.name,
    );

    await account.addAction(
      ResourceShareAction(
        resourceId: widget.resourceId,
        resourceName: resourceName!,
        user: user,
        permission: permission,
      ),
    );
  }

  Future<Permission?> _showPermissionsPicker(BuildContext context) {
    return showOptionsDialog(context, [
      permissionSetReadOnly,
      permissionSetReadWrite,
      permissionSetReadWriteShare,
    ], (p) => ListTile(leading: Icon(p.icon), title: Text(p.text)));
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
