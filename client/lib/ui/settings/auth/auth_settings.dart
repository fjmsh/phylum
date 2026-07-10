import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/auth/auth_config_controller.dart';
import 'package:phylum/ui/settings/settings.dart';

import 'auth_pane.dart';

class AuthSettings extends Settings {
  @override
  IconData get icon => Icons.perm_identity;

  @override
  String get title => 'Auth';

  @override
  String get slug => 'auth';

  @override
  List<StateNotifierProvider> get providers => [
    StateNotifierProvider<AuthConfigController, AuthConfigState>(
      create: (context) => AuthConfigController(context),
    ),
  ];

  const AuthSettings();

  @override
  Widget buildWithoutScaffold(BuildContext context) => const AuthPane();
}
