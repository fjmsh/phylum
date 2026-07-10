import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/settings/users/api/permissions_request.dart';
import 'package:phylum/libphylum/responses/user_details.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:phylum/util/dialogs.dart';

class UserPermissionsDialog extends StatefulWidget {
  final PhylumAccount account;
  final UserDetails user;

  const UserPermissionsDialog({
    super.key,
    required this.account,
    required this.user,
  });

  @override
  State<UserPermissionsDialog> createState() => _UserPermissionsDialogState();

  static Future<List<UserPermission>?> show(
    BuildContext context,
    PhylumAccount account,
    UserDetails user,
  ) {
    return showDialog(
      context: context,
      builder: (context) => UserPermissionsDialog(account: account, user: user),
    );
  }
}

class _UserPermissionsDialogState extends State<UserPermissionsDialog> {
  late final bool readOnly;
  bool requestInFlight = false;
  late List<String> options;
  late Set<String> selected;
  late List<String> filtered;

  @override
  void initState() {
    super.initState();
    readOnly = widget.user.id == widget.account.user.id;
    options = List.of(userPermissionList);
    selected = widget.user.permissions.toSet();
    final extra = widget.user.permissions.toSet()..removeAll(options);
    options.addAll(extra);
    filtered = options;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: const Text('Permissions'),
      content: SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(hintText: 'Filter'),
              onChanged: (value) {
                setState(() {
                  final query = value.toLowerCase();
                  filtered = options
                      .where(
                        (p) =>
                            p.contains(query) ||
                            p.readableName.toLowerCase().contains(query),
                      )
                      .toList(growable: false);
                });
              },
            ),
            for (final option in filtered)
              SwitchListTile(
                title: Text(option.readableName),
                value: selected.contains(option),
                onChanged: readOnly || disabled(option)
                    ? null
                    : (value) {
                        setState(() {
                          if (value) {
                            if (option == userPermissionSU) {
                              selected.clear();
                            } else {
                              for (final sel in List.of(selected)) {
                                if (sel.startsWith('$option:')) {
                                  selected.remove(sel);
                                }
                              }
                            }
                            selected.add(option);
                          } else {
                            selected.remove(option);
                          }
                        });
                      },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: readOnly || requestInFlight ? null : () => done(context),
          child: requestInFlight
              ? const Text('Updating')
              : const Text('Update'),
        ),
      ],
    );
  }

  bool disabled(UserPermission perm) {
    if (selected.contains(userPermissionSU)) {
      return perm != userPermissionSU;
    }
    for (final p in selected) {
      if (perm.startsWith('$p:')) return true;
    }
    return !widget.account.user.hasPermission(perm);
  }

  void done(BuildContext context) async {
    if (requestInFlight) return;

    setState(() => requestInFlight = true);
    final result = await widget.account.apiClient.sendRequest(
      PermissionsRequest(
        userId: widget.user.id,
        permissions: selected.toList(growable: false),
      ),
    );
    if (!context.mounted) return;
    setState(() => requestInFlight = false);
    if (result is UserDetails) {
      Navigator.of(context).pop(result.permissions);
    } else {
      showAlertDialog(
        context,
        title: 'Error Updating Permissions',
        message: result.description,
      );
    }
  }
}
