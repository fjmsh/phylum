import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:phylum/ui/config/mail/form/mail_config_form_cubit.dart';
import 'package:phylum/ui/settings/mail/mail_settings_view_material.dart';
import 'package:provider/provider.dart';

import '../../config/mail/mail_config.dart';

class MailSettingsView extends StatefulWidget {
  const MailSettingsView({super.key});

  @override
  State<MailSettingsView> createState() => _MailSettingsViewState();
}

class _MailSettingsViewState extends State<MailSettingsView> {
  late final RemoteConfigController<MailConfigFields> _remoteConfigController;
  late final MailConfigCubit _bloc;

  @override
  void initState() {
    super.initState();
    _remoteConfigController = context.read();
    _bloc = MailConfigCubit(
      remote: _remoteConfigController.config!,
      instanceUrl: context.read<PhylumAccount>().apiClient.serverUrl.toString(),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialMailSettingsView(bloc: _bloc);
  }
}
