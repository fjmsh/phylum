import 'package:flutter/material.dart';
import 'package:phylum/libphylum/account_user.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/admin_user_list_response.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:provider/provider.dart';

import 'user_list_controller.dart';

class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<UserListState>();
    final users = state.users;
    if (users == null) {
      if (state.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (state.error != null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error loading User List: ${state.error}'),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              onPressed: () {
                context.read<UserListController>().fetch();
              },
              child: Text('Retry'),
            ),
          ],
        );
      }
      return Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          onPressed: () {
            context.read<UserListController>().fetch();
          },
          child: Text('Load User List'),
        ),
      );
    }
    return ChipTheme(
      data: ChipThemeData(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        labelPadding: EdgeInsets.zero,
      ),
      child: ListView.builder(
        itemBuilder: (context, i) {
          final user = users[i];
          return ListTile(
            title: Text.rich(TextSpan(children: [
              if (user.name.isNotEmpty) TextSpan(text: '${user.name} \u2022 '),
              TextSpan(
                  text: user.email,
                  style: TextStyle(fontStyle: FontStyle.italic))
            ])),
            subtitle: Wrap(
              alignment: WrapAlignment.start,
              spacing: 6,
              runSpacing: 6,
              children: user.permissions
                  .map((p) => Chip(label: Text(p.readableName)))
                  .toList(growable: false),
            ),
            onTap: () => showUserDetails(context, user),
          );
        },
        itemCount: users.length,
      ),
    );
  }

  void showUserDetails(BuildContext context, UserDetails user) {
    final loggedInUser = context.read<PhylumAccount>().user;
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
                      visualDensity:
                          const VisualDensity(horizontal: -4, vertical: -4)),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Name'),
                        subtitle: Text(user.name),
                      ),
                      ListTile(
                        title: const Text('Email'),
                        subtitle: Text(user.email),
                      ),
                      ListTile(
                        title: const Text('User ID'),
                        subtitle: Text(user.id.toString()),
                      ),
                      ListTile(
                        title: Text('Permissions'),
                        subtitle: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 6,
                          runSpacing: 6,
                          children: user.permissions
                              .map((p) => Chip(label: Text(p.readableName)))
                              .toList(growable: false),
                        ),
                        onTap: loggedInUser
                                .hasPermission(userPermissionUsersGrant)
                            ? () async {
                                final permissions = await showPermissionsDialog(
                                    context, user, loggedInUser);
                                if (permissions == null || !context.mounted) {
                                  return;
                                }
                                final result = await controller
                                    .updatePermissions(user, permissions);
                                messenger.showSnackBar(SnackBar(
                                    content: result == null
                                        ? const Text('Permissions Updated')
                                        : Text(result)));
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Okay'))
              ],
            ));
  }

  Future<List<UserPermission>?> showPermissionsDialog(
    BuildContext context,
    UserDetails user,
    AccountUser loggedInUser,
  ) async {
    final readOnly = user.id == loggedInUser.id;

    final options = [
      userPermissionSU,
      userPermissionInvite,
      userPermissionFilesAll,
      userPermissionFilesRead,
      userPermissionFilesWrite,
      userPermissionFilesShare,
      userPermissionUsersAll,
      userPermissionUsersList,
      userPermissionUsersAdd,
      userPermissionUsersGrant,
    ];
    final selected = Set.of(user.permissions);
    bool disabled(UserPermission perm) {
      if (selected.contains(userPermissionSU)) {
        return perm != userPermissionSU;
      }
      return switch (perm) {
        userPermissionFilesRead ||
        userPermissionFilesWrite ||
        userPermissionFilesShare =>
          selected.contains(userPermissionFilesAll),
        userPermissionUsersList ||
        userPermissionUsersAdd ||
        userPermissionUsersGrant =>
          selected.contains(userPermissionUsersAll),
        // Do not allow selecting permissions we don't have ourselvese
        _ => !loggedInUser.hasPermission(perm),
      };
    }

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          scrollable: true,
          title: const Text('Permissions'),
          content: SizedBox(
            width: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final option in options)
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
                            }),
              ],
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error),
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: readOnly
                  ? null
                  : () => Navigator.of(context)
                      .pop(List.of(selected).toList(growable: false)),
              child: Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
