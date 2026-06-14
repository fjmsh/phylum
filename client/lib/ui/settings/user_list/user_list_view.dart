import 'package:flutter/material.dart';
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
              // children: [
              //   Chip(label: Text('Permissions')),
              //   Chip(label: Text('Permissions')),
              //   Chip(label: Text('Permissions')),
              // ],
            ),
            // subtitle: Text(user.email),
          );
        },
        itemCount: users.length,
      ),
    );
  }
}
