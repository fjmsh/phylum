import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/layout/responsive.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/ui/settings/settings_controller.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();

  static Widget create(PhylumAccount account) {
    return Provider<PhylumAccount>.value(
        value: account,
        child: StateNotifierProvider<SettingsController, SettingsState>(
          create: (context) => SettingsController(),
          child: MultiProvider(
            providers: settingsList
                .whereType<Settings>()
                .map((s) => s.providers)
                .flattened
                .toList(growable: false),
            child: const SettingsPage(),
          ),
        ));
  }
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width > minViewportWidthMedium) {
      return buildMasterDetail(context, width);
    }
    final selected =
        context.select<SettingsState, Settings?>((state) => state.selected);
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
      appBar: AppBar(
        title: Text('Settings'),
        leading: CloseButton(),
      ),
      body: ListView.builder(
        itemCount: settingsList.length,
        itemBuilder: (context, i) =>
            settingsList[i].buildMenuItem(context, false),
      ),
    );
  }

  Widget buildMasterDetail(BuildContext context, double width) {
    final selected =
        context.select<SettingsState, Settings?>((state) => state.selected) ??
            settingsList[0] as Settings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings - ${selected.title}'),
        leading: CloseButton(),
      ),
      body: Center(
        child: SizedBox(
          width: 1000,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 240,
                child: ListView.builder(
                  itemCount: settingsList.length,
                  itemBuilder: (context, i) => settingsList[i]
                      .buildMenuItem(context, settingsList[i] == selected),
                ),
              ),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(16),
                child: selected.buildWithoutScaffold(context),
              )),
            ],
          ),
        ),
      ),
    );
  }
}
