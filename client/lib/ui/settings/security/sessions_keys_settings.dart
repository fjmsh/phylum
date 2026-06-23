import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/settings.dart';

import 'sessions_keys_pane.dart';

class SesssionsKeysSettings extends Settings {
  @override
  IconData get icon => Icons.security;

  @override
  String get title => 'Sessions and Keys';

  @override
  String get slug => 'sessions-keys';

  const SesssionsKeysSettings();

  @override
  List<StateNotifierProvider> get providers => const [];

  @override
  Widget buildWithoutScaffold(BuildContext context) => const SessionsKeysView();
}
