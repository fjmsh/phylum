import 'package:flutter/material.dart';
import 'package:phylum/ui/settings/user_list/user_list_controller.dart';
import 'package:phylum/util/user_display_name.dart';
import 'package:provider/provider.dart';

class UserListView extends StatelessWidget {
  const UserListView({super.key});

  @override
  Widget build(BuildContext context) {
    final users = context.watch<UserList>().users;
    if (users == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemBuilder: (context, i) {
        final user = users[i];
        return ListTile(
          title: Text(user.displayName),
          subtitle: Text(user.email),
        );
      },
      itemCount: users.length,
    );
  }
}
