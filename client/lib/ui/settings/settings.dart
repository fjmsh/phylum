import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings_controller.dart';
import 'package:phylum/ui/settings/user_list/user_list_page.dart';
import 'package:phylum/ui/settings/user_list/user_list_controller.dart';
import 'package:phylum/ui/settings/user_list/user_list_panel.dart';
import 'package:provider/provider.dart';

const settingsList = <SettingsItem>[
  UserSettings(),
  TitleSettingsItem(title: 'About'),
];

sealed class SettingsItem {
  const SettingsItem();

  Widget buildMenuItem(BuildContext context, bool selected);
}

class TitleSettingsItem extends SettingsItem {
  final String title;

  const TitleSettingsItem({required this.title});
  @override
  Widget buildMenuItem(BuildContext context, bool selected) => ListTile(
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        dense: true,
      );
}

sealed class Settings extends SettingsItem {
  const Settings();

  IconData get icon;

  String get title;

  List<StateNotifierProvider> get providers;

  @override
  Widget buildMenuItem(BuildContext context, bool selected) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        selected: selected,
        onTap: () => context.read<SettingsController>().updateSelected(this),
      );

  Widget buildWithScaffold(BuildContext context);

  Widget buildWithoutScaffold(BuildContext context);
}

class UserSettings extends Settings {
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
  Widget buildWithScaffold(BuildContext context) => const UserListPage();

  @override
  Widget buildWithoutScaffold(BuildContext context) => const UserListPanel();
}
