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
  final RemoteConfigController<AuthConfig> _remoteConfigController;

  const AuthConfigPane({super.key, required this._remoteConfigController});

  @override
  State<AuthConfigPane> createState() => _AuthConfigPaneState();
}

class _AuthConfigPaneState extends State<AuthConfigPane> {
  late final AuthConfigPaneCubit configBloc;
  late final AuthConfigSaveCubit saveBloc;
  late final void Function() _removeServerConfigListener;

  @override
  void initState() {
    super.initState();
    configBloc = AuthConfigPaneCubit(
      account: context.read(),
      remoteConfigController: widget._remoteConfigController,
    );
    saveBloc = AuthConfigSaveCubit(
      account: context.read(),
      remoteConfigController: widget._remoteConfigController,
    );
    _removeServerConfigListener = context
        .read<PhylumAccount>()
        .configNotifier
        .addListener((config) {
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
      providers: [
        BlocProvider<AuthConfigFormCubit>.value(value: configBloc),
        BlocProvider.value(value: saveBloc),
      ],
      child: MaterialAuthConfigPane(
        configBloc: configBloc,
        saveBloc: saveBloc,
      ), //TODO #uilibrary
    );
  }
}
