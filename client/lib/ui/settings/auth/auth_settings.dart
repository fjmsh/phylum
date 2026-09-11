import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/config/auth/auth_config.dart';
import 'package:phylum/ui/config/config.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:phylum/ui/config/remote_config_pane.dart';
import 'package:phylum/ui/settings/settings.dart';

import 'auth_settings_view.dart';

class AuthSettings extends Settings {
  @override
  IconData get icon => Icons.perm_identity;

  @override
  String get title => 'Auth';

  @override
  String get slug => 'auth';

  @override
  List<StateNotifierProvider> get providers => [
    StateNotifierProvider<
      RemoteConfigController<AuthConfigFields>,
      RemoteConfigState<AuthConfigFields>
    >(
      create: (context) => RemoteConfigController(
        context,
        baseRoute: '/api/v1/admin/config/auth',
        parseConfig: (data) =>
            RemoteConfig.fromMap(AuthConfigFields.instance, data),
      ),
    ),
  ];

  const AuthSettings();

  @override
  Widget buildWithoutScaffold(BuildContext context) =>
      const RemoteConfigPane<AuthConfigFields>(child: AuthSettingsView());
}
