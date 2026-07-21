import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
import 'package:phylum/ui/settings/mail/form/mail_config_form_cubit.dart';
import 'package:phylum/ui/settings/mail/mail_config_pane_material.dart';
import 'package:provider/provider.dart';

import 'mail_config.dart';

class MailConfigPane extends StatefulWidget {
  const MailConfigPane({super.key});

  @override
  State<MailConfigPane> createState() => _MailConfigPaneState();
}

class _MailConfigPaneState extends State<MailConfigPane> {
  late final RemoteConfigController<MailConfig> _remoteConfigController;
  late final MailConfigFormCubit bloc;

  @override
  void initState() {
    super.initState();
    _remoteConfigController = context.read();
    bloc = MailConfigFormCubit(config: _remoteConfigController.config!);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [BlocProvider<MailConfigFormCubit>.value(value: bloc)],
      child: const MaterialMailConfigPane(), //TODO #uilibrary
    );
  }
}
