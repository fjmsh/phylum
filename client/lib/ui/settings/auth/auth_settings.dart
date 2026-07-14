import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
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
    StateNotifierProvider<
      RemoteConfigController<AuthConfig>,
      RemoteConfigState<AuthConfig>
    >(
      create: (context) => RemoteConfigController(
        context,
        endpoint: '/api/v1/admin/config/auth/read',
        parseConfig: AuthConfig.fromMap,
      ),
    ),
  ];

  const AuthSettings();

  @override
  Widget buildWithoutScaffold(BuildContext context) => const AuthPane();
}
