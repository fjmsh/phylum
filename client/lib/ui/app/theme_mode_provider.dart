import 'package:flutter/material.dart';
import 'package:phylum/util/prefs/prefs.dart';
import 'package:state_notifier/state_notifier.dart';

const prefsKeyPreferredThemeMode = 'preferredThemeMode';

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(restorePreferredMode());

  static ThemeMode restorePreferredMode() =>
      switch (Prefs.get().getString(prefsKeyPreferredThemeMode)) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  set preferredMode(ThemeMode mode) {
    state = mode;
    final modeStr = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'auto',
    };
    Prefs.get().setString(prefsKeyPreferredThemeMode, modeStr);
  }
}
