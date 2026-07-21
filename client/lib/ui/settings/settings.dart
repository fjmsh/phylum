import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/app/routing/router.dart';
import 'package:phylum/ui/settings/account/account_settings.dart';
import 'package:phylum/ui/settings/appearance/appearance_settings.dart';
import 'package:phylum/ui/settings/auth/auth_settings.dart';
import 'package:phylum/ui/settings/downloads/downloads_settings.dart';
import 'package:phylum/ui/settings/logs/logs_settings.dart';
import 'package:phylum/ui/settings/mail/mail_settings.dart';
import 'package:phylum/ui/settings/security/sessions_keys_settings.dart';
import 'package:phylum/ui/settings/sync/sync_settings.dart';
import 'package:phylum/ui/settings/users/users_settings.dart';
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
    onTap: () =>
        context.read<PhylumRouterDelegate>().go(SettingsRoute(selected: this)),
  );

  Widget buildWithScaffold(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: buildWithoutScaffold(context),
  );

  Widget buildWithoutScaffold(BuildContext context);

  static Settings? parseSlug(String? slug) {
    final map = {
      const AccountSettings().slug: AccountSettings(),
      const AppearanceSettings().slug: AppearanceSettings(),
      const SesssionsKeysSettings().slug: SesssionsKeysSettings(),
      const SyncSettings().slug: SyncSettings(),
      const DownloadsSettings().slug: DownloadsSettings(),
      const LogsSettings().slug: LogsSettings(),
      const UsersSettings().slug: UsersSettings(),
      const AuthSettings().slug: AuthSettings(),
      const MailSettings().slug: MailSettings(),
    };
    return map[slug];
  }
}
