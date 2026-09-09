import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:provider/provider.dart';

import 'auth_config.dart';
import 'auth_settings_pane_cubit.dart';
import 'auth_settings_pane_material.dart';
import 'form/auth_config_form_cubit.dart';

class AuthSettingsPane extends StatefulWidget {
  const AuthSettingsPane({super.key});

  @override
  State<AuthSettingsPane> createState() => _AuthSettingsPaneState();
}

class _AuthSettingsPaneState extends State<AuthSettingsPane> {
  late final RemoteConfigController<AuthConfigFields> _remoteConfigController;
  late final AuthConfigPaneCubit configBloc;
  late final void Function() _removeServerConfigListener;

  @override
  void initState() {
    super.initState();
    _remoteConfigController = context.read();
    final account = context.read<PhylumAccount>();
    configBloc = AuthConfigPaneCubit(
      account: account,
      remote: _remoteConfigController.config!,
    );
    _removeServerConfigListener = account.configNotifier.addListener((config) {
      configBloc.mailEnabled = config.mail;
    });
  }

  @override
  void dispose() {
    _removeServerConfigListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [BlocProvider<AuthConfigCubit>.value(value: configBloc)],
      child: MaterialAuthSettingsPane(configBloc: configBloc), //TODO #uilibrary
    );
  }
}
