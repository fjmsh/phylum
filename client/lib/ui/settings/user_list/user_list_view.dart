import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/user_details.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:phylum/ui/app/routing/explorer_location.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/app/routing/routes.dart';
import 'package:phylum/ui/common/create_user_dialog.dart';
import 'package:phylum/ui/common/new_user_details_dialog.dart';
import 'package:phylum/ui/settings/user_list/user_permissions_dialog.dart';
import 'package:provider/provider.dart';

import 'user_list_controller.dart';

class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.read<PhylumAccount>();
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
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onPrimaryContainer,
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
      child: Stack(
        children: [
          ListView.builder(
            itemBuilder: (context, i) {
              final user = users[i];
              return ListTile(
                title: Text.rich(
                  TextSpan(
                    children: [
                      if (user.name.isNotEmpty)
                        TextSpan(text: '${user.name} \u2022 '),
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
                trailing:
                    account.user.hasPermission(userPermissionFilesRead) &&
                        user.home != null
                    ? IconButton(
                        icon: Icon(Icons.folder_open_rounded),
                        onPressed: () {
                          context.read<PhylumRouterDelegate>().go(
                            ExplorerRoute(
                              location: ExplorerLocationFolder(
                                folderId: user.home!,
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              );
            },
            itemCount: users.length,
          ),
          if (account.user.hasPermission(userPermissionUsersCreateInvite))
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton(
                  onPressed: () async {
                    if (account.user.hasPermission(userPermissionUsersCreate)) {
                      final controller = context.read<UserListController>();
                      final user = await CreateUserDialog.show(context);
                      if (user == null) return;
                      controller.addUser(user);
                    } else {
                      final account = context.read<PhylumAccount>();
                      final userDetails = await NewUserDetailsDialog.show(
                        context,
                      );
                      if (userDetails == null || !context.mounted) return;
                      await account.userRepository.invite(
                        email: userDetails.email,
                        name: userDetails.name,
                      );
                    }
                  },
                  child: Icon(Icons.add),
                ),
              ),
            ),
        ],
      ),
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
