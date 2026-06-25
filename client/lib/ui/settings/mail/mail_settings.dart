import 'package:flutter/material.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:phylum/ui/settings/mail/mail_config_controller.dart';
import 'package:phylum/ui/settings/mail/mail_pane.dart';
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
    StateNotifierProvider<MailConfigController, MailConfigState>(
      create: (context) => MailConfigController(context),
    ),
  ];

  const MailSettings();

  @override
  Widget buildWithoutScaffold(BuildContext context) => const MailPane();
}
