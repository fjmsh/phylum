import 'package:flutter/material.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:phylum/ui/common/create_user_dialog.dart';
import 'package:phylum/ui/common/new_user_details_dialog.dart';
import 'package:phylum/ui/settings/users/user_details_item.dart';
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
        return Center(
          child: Column(
            mainAxisAlignment: .center,
            crossAxisAlignment: .center,
            spacing: 18,
            children: [
              Text('Error loading User List: ${state.error}'),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
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
          ),
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
            itemBuilder: (context, i) => UserDetailsItem(users[i]),
            itemCount: users.length,
          ),
          if ((account.config.mail &&
                  (account.config.allowInvites ||
                      account.user.hasPermission(
                        userPermissionUsersCreateInvite,
                      ))) ||
              account.user.hasPermission(userPermissionUsersCreate))
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
}
