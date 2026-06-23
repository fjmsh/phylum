import 'package:flutter/material.dart';
import 'package:phylum/ui/common/breakpoints.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/ui/settings/settings_controller.dart';
import 'package:provider/provider.dart';

class SettingsView extends StatelessWidget {
  final List<SettingsItem> items;

  const SettingsView({super.key, required this.items});

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
        itemCount: items.length,
        itemBuilder: (context, i) => items[i].buildMenuItem(context, false),
      ),
    );
  }

  Widget buildMasterDetail(BuildContext context, double width) {
    final selected =
        context.select<SettingsState, Settings?>((state) => state.selected) ??
        items.firstWhere((s) => s is Settings) as Settings;

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
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      items[i].buildMenuItem(context, items[i] == selected),
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
