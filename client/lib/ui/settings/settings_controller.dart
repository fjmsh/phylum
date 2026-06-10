import 'package:flutter_state_notifier/flutter_state_notifier.dart';

import 'settings.dart';

class SettingsState {
  final Settings? selected;

  const SettingsState({required this.selected});
}

class SettingsController extends StateNotifier<SettingsState> {
  SettingsController() : super(const SettingsState(selected: null));

  void updateSelected(Settings? selected) {
    state = SettingsState(selected: selected);
  }
}
