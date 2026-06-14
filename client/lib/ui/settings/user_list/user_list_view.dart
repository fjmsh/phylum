import 'package:flutter/material.dart';
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
