import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings_controller.dart';
import 'package:provider/provider.dart';

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

abstract class Settings extends SettingsItem {
  const Settings();

  IconData get icon;

  String get title;

  String get slug;

  List<StateNotifierProvider> get providers;

  @override
  Widget buildMenuItem(BuildContext context, bool selected) => ListTile(
    leading: Icon(icon),
    title: Text(title),
    selected: selected,
    onTap: () => context.read<SettingsController>().updateSelected(this),
  );

  Widget buildWithScaffold(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: buildWithScaffold(context),
  );

  Widget buildWithoutScaffold(BuildContext context);
}
