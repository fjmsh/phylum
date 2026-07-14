import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/libphylum/config/mail_config.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
import 'package:phylum/ui/settings/config/remote_config_pane.dart';
import 'package:phylum/ui/settings/mail/mail_config_form.dart';
import 'package:phylum/ui/settings/settings.dart';

class MailSettings extends Settings {
  @override
  IconData get icon => Icons.mail;

  @override
  String get title => 'Mail';

  @override
  String get slug => 'mail';

  @override
  List<StateNotifierProvider> get providers => [
    StateNotifierProvider<
      RemoteConfigController<MailConfig>,
      RemoteConfigState<MailConfig>
    >(
      create: (context) => RemoteConfigController<MailConfig>(
        context,
        endpoint: '/api/v1/admin/config/mail/read',
        parseConfig: MailConfig.fromMap,
      ),
    ),
  ];

  const MailSettings();

  @override
  Widget buildWithoutScaffold(BuildContext context) =>
      RemoteConfigPane<MailConfig>(
        builder: (context, config) => MailConfigForm(initialConfig: config),
      );
}
