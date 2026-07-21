import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/app/theme_mode_provider.dart';
import 'package:phylum/ui/settings/settings.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:provider/provider.dart';

class AppearanceSettings extends Settings {
  @override
  IconData get icon => Icons.brush;

  @override
  String get title => 'Appearance';

  @override
  String get slug => 'appearnce';

  const AppearanceSettings();

  @override
  List<StateNotifierProvider> get providers => const [];

  @override
  Widget buildWithoutScaffold(BuildContext context) => AppearanceSettingsPane();
}

class AppearanceSettingsPane extends StatelessWidget {
  const AppearanceSettingsPane({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Column(
            children: [
              Builder(
                builder: (context) => ListTile(
                  leading: Icon(Icons.brightness_4),
                  title: Text('Theme'),
                  subtitle: Text(context.watch<ThemeMode>().description),
                  onTap: () async {
                    final mode = await showOptionsDialog(
                      context,
                      [ThemeMode.light, ThemeMode.dark, ThemeMode.system],
                      (mode) => ListTile(
                        leading: Icon(mode.icon),
                        title: Text(mode.description),
                      ),
                    );
                    if (mode == null || !context.mounted) return;
                    context.read<ThemeModeNotifier>().preferredMode = mode;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

extension on ThemeMode {
  String get description => switch (this) {
    ThemeMode.system => 'System (Auto)',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  IconData get icon => switch (this) {
    ThemeMode.system => Icons.brightness_auto,
    ThemeMode.light => Icons.brightness_7,
    ThemeMode.dark => Icons.brightness_3,
  };
}
