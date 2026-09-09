import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:phylum/ui/config/mail/form/mail_config_form_cubit.dart';
import 'package:phylum/ui/config/mail/mail_config_pane_material.dart';
import 'package:provider/provider.dart';

import 'mail_config.dart';

class MailConfigPane extends StatefulWidget {
  const MailConfigPane({super.key});

  @override
  State<MailConfigPane> createState() => _MailConfigPaneState();
}

class _MailConfigPaneState extends State<MailConfigPane> {
  late final RemoteConfigController<MailConfigFields> _remoteConfigController;
  late final MailConfigCubit _bloc;

  @override
  void initState() {
    super.initState();
    _remoteConfigController = context.read();
    _bloc = MailConfigCubit(
      remoteConfig: _remoteConfigController.config!,
      instanceUrl: context.read<PhylumAccount>().apiClient.serverUrl.toString(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialMailConfigPane(bloc: _bloc);
  }
}
