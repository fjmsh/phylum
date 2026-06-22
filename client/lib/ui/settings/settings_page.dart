import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/ui/settings/account/account_settings.dart';
import 'package:phylum/ui/settings/downloads/downloads_settings.dart';
import 'package:phylum/ui/settings/logs/logs_settings.dart';
import 'package:phylum/ui/settings/security/sessions_keys_settings.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/ui/settings/settings_controller.dart';
import 'package:phylum/ui/settings/sync/sync_settings.dart';
import 'package:phylum/ui/settings/user_list/users_settings.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  final List<SettingsItem> settingsList;
  const SettingsPage({super.key, required this.settingsList});

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Widget create(PhylumAccount account, {Settings? selected}) {
    final settingsList = _getSettingsList(account);
    return MultiProvider(
      providers: [
        Provider<PhylumAccount>.value(value: account),
        StateNotifierProvider<
          ApiActionQueue<PhylumAccount>,
          ApiActionQueueState<PhylumAccount>
        >.value(value: account.actionQueue),
        StateNotifierProvider<SettingsController, SettingsState>(
          create: (context) => SettingsController(selected),
        ),
        ...settingsList.whereType<Settings>().map((s) => s.providers).flattened,
      ],
      child: SettingsPage(settingsList: settingsList),
    );
  }
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > minViewportWidthMedium) {
      return buildMasterDetail(context, width);
    }
    final selected = context.select<SettingsState, Settings?>(
      (state) => state.selected,
    );
    if (selected != null) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          context.read<SettingsController>().updateSelected(null);
        },
        child: selected.buildWithScaffold(context),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Settings'), leading: CloseButton()),
      body: ListView.builder(
        itemCount: widget.settingsList.length,
        itemBuilder: (context, i) =>
            widget.settingsList[i].buildMenuItem(context, false),
      ),
    );
  }

  Widget buildMasterDetail(BuildContext context, double width) {
    final selected =
        context.select<SettingsState, Settings?>((state) => state.selected) ??
        widget.settingsList.firstWhere((s) => s is Settings) as Settings;

    return Scaffold(
      appBar: AppBar(title: Text(selected.title), leading: CloseButton()),
      body: Center(
        child: SizedBox(
          width: 1000,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 240,
                child: ListView.builder(
                  itemCount: widget.settingsList.length,
                  itemBuilder: (context, i) =>
                      widget.settingsList[i].buildMenuItem(
                        context,
                        widget.settingsList[i] == selected,
                      ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: selected.buildWithoutScaffold(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<SettingsItem> _getSettingsList(PhylumAccount account) {
  final list = <SettingsItem>[
    AccountSettings(),
    SesssionsKeysSettings(),
    SyncSettings(),
    if (!kIsWeb) DownloadsSettings(),
    LogsSettings(),
  ];

  final adminSettings = <SettingsItem>[
    if (account.user.hasPermission('users:list')) UsersSettings(),
  ];

  if (adminSettings.isNotEmpty) {
    list.add(TitleSettingsItem(title: 'Admin'));
    list.addAll(adminSettings);
  }
  return list;
}
