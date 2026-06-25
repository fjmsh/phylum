import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/ui/settings/users/users_page.dart';

import 'user_list_controller.dart';
import 'users_pane.dart';

class UsersSettings extends Settings {
  @override
  IconData get icon => Icons.people;

  @override
  String get title => 'Users';

  @override
  String get slug => 'users';

  @override
  List<StateNotifierProvider> get providers => [
    StateNotifierProvider<UserListController, UserListState>(
      create: (context) => UserListController(context),
    ),
  ];

  const UsersSettings();

  @override
  Widget buildWithScaffold(BuildContext context) => const UsersPage();

  @override
  Widget buildWithoutScaffold(BuildContext context) => const UsersPane();
}
