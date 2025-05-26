import 'dart:async';

import 'package:drift/drift.dart' show TableOrViewStatements;
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/actions/action_resource_share.dart';
import 'package:phylum/libphylum/actions/action_user_invite.dart';
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
                    buildLastItem: (context) => ListTile(
                      leading: Icon(Icons.person_add),
                      title: Text('Invite'),
                      onTap: () async {
                        String email = '';
                        String name = '';
                        bool confirm = await showDialog(
                              // ignore: use_build_context_synchronously
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => StatefulBuilder(builder: (context, setState) {
                                return AlertDialog(
                                  title: const Text('Invite User'),
                                  content: SizedBox(
                                    width: 360,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 12.0,
                                      children: [
                                        TextField(
                                          decoration: InputDecoration(
                                            labelText: 'Email',
                                            hintText: 'djarin@example.com',
                                          ),
                                          autofocus: true,
                                          textCapitalization: TextCapitalization.none,
                                          keyboardType: TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          onChanged: (value) {
                                            setState(() {
                                              email = value;
                                            });
                                          },
                                        ),
                                        TextField(
                                          decoration: InputDecoration(
                                            labelText: 'Name (optional)',
                                            hintText: 'Din Djarin',
                                          ),
                                          textCapitalization: TextCapitalization.words,
                                          keyboardType: TextInputType.name,
                                          textInputAction: TextInputAction.go,
                                          onChanged: (value) {
                                            name = value;
                                          },
                                          onSubmitted:
                                              email.isEmpty ? null : (value) => Navigator.of(context).pop(true),
                                        ),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                                      ),
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                      },
                                    ),
                                    ElevatedButton(
                                      onPressed: email.isEmpty ? null : () => Navigator.of(context).pop(true),
                                      child: const Text('Invite'),
                                    )
                                  ],
                                );
                              }),
                            ) ??
                            false;

                        if (!confirm || !context.mounted) return;
                        account.addAction(UserInviteAction(email: email, displayName: name));
                      },
                    ),
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
              leading: Icon(e.value.icon),
              title: Text(repository.getUserDisplayName(e.key)),
              subtitle: Text(e.value.text),
              onTap: (userPermission! & permissionShare) == 0
                  ? null
                  : () async {
                      final permission = await showOptionsDialogBuilder(
                        context,
                        [
                          permissionSetNone,
                          permissionSetReadOnly,
                          permissionSetReadWrite,
                          permissionSetReadWriteShare,
                        ],
                        (p) => ListTile(leading: Icon(p.icon), title: Text(p.text)),
                      );
                      if (permission == null || permission == e.value) return;
                      final user =
                          await (account.db.users.select()..where((u) => u.id.equals(e.key))).getSingleOrNull();
                      if (user == null) return;

                      account.addAction(ResourceShareAction(
                        resourceId: widget.resourceId,
                        resourceName: resourceName!,
                        user: user,
                        permission: permission,
                      ));
                    },
            ),
          ListTile(
            visualDensity: VisualDensity.compact,
            dense: true,
            title: const Text(
                key: ValueKey('inherited'), 'Inherited Permissions', style: TextStyle(fontWeight: FontWeight.bold)),
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
