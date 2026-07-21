import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
import 'package:provider/provider.dart';

import 'auth_config.dart';
import 'auth_config_pane_cubit.dart';
import 'auth_config_pane_material.dart';
import 'form/auth_config_form_cubit.dart';

class AuthConfigPane extends StatefulWidget {
  const AuthConfigPane({super.key});

  @override
  State<AuthConfigPane> createState() => _AuthConfigPaneState();
}

class _AuthConfigPaneState extends State<AuthConfigPane> {
  late final RemoteConfigController<AuthConfig> _remoteConfigController;
  late final AuthConfigPaneCubit configBloc;
  late final void Function() _removeServerConfigListener;

  @override
  void initState() {
    super.initState();
    _remoteConfigController = context.read();
    final account = context.read<PhylumAccount>();
    configBloc = AuthConfigPaneCubit(
      account: account,
      initialConfig: _remoteConfigController.config ?? AuthConfig.defaults(),
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
      providers: [BlocProvider<AuthConfigFormCubit>.value(value: configBloc)],
      child: MaterialAuthConfigPane(configBloc: configBloc), //TODO #uilibrary
    );
  }
}
