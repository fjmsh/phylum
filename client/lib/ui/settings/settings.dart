import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings_controller.dart';
import 'package:phylum/ui/settings/user_list/user_list.dart';
import 'package:phylum/ui/settings/user_list/user_list_controller.dart';
import 'package:provider/provider.dart';

const settingsList = <Settings>[
  UserSettings(),
];

sealed class Settings {
  const Settings();

  List<StateNotifierProvider> get providers;

  Widget buildTitle(BuildContext context);

  Widget buildWithScaffold(BuildContext context);

  Widget buildWithoutScaffold(BuildContext context);
}

sealed class SimpleSettings extends Settings {
  const SimpleSettings();

  IconData get icon;

  String get title;

  @override
  Widget buildTitle(BuildContext context) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        onTap: () => context.read<SettingsController>().updateSelected(this),
      );
}

class UserSettings extends SimpleSettings {
  @override
  IconData get icon => Icons.people;

  @override
  String get title => 'Users';

  @override
  List<StateNotifierProvider> get providers => [
        StateNotifierProvider<UserListController, UserList>(
            create: (context) => UserListController(context))
      ];

  const UserSettings();

  @override
  Widget buildWithScaffold(BuildContext context) => UserListPage();

  @override
  Widget buildWithoutScaffold(BuildContext context) {
    throw UnimplementedError();
  }
}
