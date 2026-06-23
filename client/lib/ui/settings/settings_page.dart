import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/settings/account/account_settings.dart';
import 'package:phylum/ui/settings/downloads/downloads_settings.dart';
import 'package:phylum/ui/settings/logs/logs_settings.dart';
import 'package:phylum/ui/settings/security/sessions_keys_settings.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/ui/settings/settings_view.dart';
import 'package:phylum/ui/settings/sync/sync_settings.dart';
import 'package:phylum/ui/settings/user_list/users_settings.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  final PhylumAccount account;
  final Settings? selected;

  const SettingsPage({
    super.key,
    required this.account,
    required this.selected,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final List<SettingsItem> items;
  Settings? selected;

  @override
  void initState() {
    super.initState();
    items = _buildItems();
    selected = items.contains(widget.selected) ? widget.selected : null;
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    selected = widget.selected;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PhylumAccount>.value(value: widget.account),
        StateNotifierProvider<
          ApiActionQueue<PhylumAccount>,
          ApiActionQueueState<PhylumAccount>
        >.value(value: widget.account.actionQueue),
        ...items.whereType<Settings>().map((s) => s.providers).flattened,
      ],
      child: SettingsView(items: items, selected: selected),
    );
  }

  List<SettingsItem> _buildItems() {
    final list = <SettingsItem>[
      AccountSettings(),
      SesssionsKeysSettings(),
      SyncSettings(),
      if (!kIsWeb) DownloadsSettings(),
      LogsSettings(),
    ];

    final adminSettings = <SettingsItem>[
      if (widget.account.user.hasPermission('users:list')) UsersSettings(),
    ];

    if (adminSettings.isNotEmpty) {
      list.add(TitleSettingsItem(title: 'Admin'));
      list.addAll(adminSettings);
    }
    return list;
  }
}
