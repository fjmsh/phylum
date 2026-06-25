import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/user_details.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/settings/users/password_change_dialog.dart';
import 'package:phylum/ui/settings/users/user_list_controller.dart';
import 'package:phylum/ui/settings/users/user_permissions_dialog.dart';
import 'package:provider/provider.dart';

class UserDetailsItem extends StatelessWidget {
  final UserDetails user;

  UserDetailsItem(this.user) : super(key: ValueKey(user.id));

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text.rich(
        TextSpan(
          children: [
            if (user.name.isNotEmpty) TextSpan(text: '${user.name} \u2022 '),
            TextSpan(
              text: user.email,
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      subtitle: user.permissions.isEmpty
          ? const Text(
              'No Permissions',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          : Wrap(
              alignment: WrapAlignment.start,
              spacing: 6,
              runSpacing: 6,
              children: user.permissions
                  .map((p) => Chip(label: Text(p.readableName)))
                  .toList(growable: false),
            ),
      onTap: () => showUserDetails(context, user),
    );
  }

  void showUserDetails(BuildContext context, UserDetails user) {
    final account = context.read<PhylumAccount>();
    final controller = context.read<UserListController>();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: SizedBox(
          width: 360,
          child: ListTileTheme(
            data: ListTileThemeData(
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(title: const Text('Name'), subtitle: Text(user.name)),
                ListTile(
                  title: const Text('Email'),
                  subtitle: Text(user.email),
                ),
                ListTile(
                  title: const Text('User ID'),
                  subtitle: Text(user.id.toString()),
                ),
                StatefulBuilder(
                  builder: (context, setState) {
                    return ListTile(
                      title: Text('Permissions'),
                      subtitle: user.permissions.isEmpty
                          ? const Text(
                              'None',
                              style: TextStyle(fontStyle: FontStyle.italic),
                            )
                          : Wrap(
                              alignment: WrapAlignment.start,
                              spacing: 6,
                              runSpacing: 6,
                              children: user.permissions
                                  .map((p) => Chip(label: Text(p.readableName)))
                                  .toList(growable: false),
                            ),
                      onTap:
                          account.user.hasPermission(
                            userPermissionUsersPermissions,
                          )
                          ? () async {
                              final updatedPermissions =
                                  await UserPermissionsDialog.show(
                                    context,
                                    account,
                                    user,
                                  );
                              if (updatedPermissions == null ||
                                  !context.mounted) {
                                return;
                              }
                              setState(() {
                                user = user.copyWith(
                                  permissions: updatedPermissions,
                                );
                              });
                              controller.updateUser(user);
                              messenger.showSnackBar(
                                SnackBar(
                                  content: const Text('Permissions Updated'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                    );
                  },
                ),
                if (account.user.hasPermission(userPermissionFilesRead) &&
                    user.home != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.folder_open_rounded),
                      label: Text('View Files'),
                      onPressed: () {
                        context.read<PhylumRouterDelegate>().go(
                          ExplorerRoute(
                            location: ExplorerLocationFolder(
                              folderId: user.home!,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (account.user.hasPermission(
                      userPermissionUsersAuthPasswordUpdate,
                    ) &&
                    account.config.passwordUpdate)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.password),
                      label: Text('Change Password'),
                      onPressed: () =>
                          PasswordChangeDialog.show(context, account, user),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Okay'),
          ),
        ],
      ),
    );
  }
}
