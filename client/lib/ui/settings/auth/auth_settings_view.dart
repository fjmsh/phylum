import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/config/remote_config_controller.dart';
import 'package:phylum/ui/settings/auth/crypt_settings_cubit.dart';
import 'package:provider/provider.dart';

import '../../config/auth/auth_config.dart';
import 'auth_settings_view_material.dart';
import '../../config/auth/auth_config_cubit.dart';

class AuthSettingsView extends StatefulWidget {
  const AuthSettingsView({super.key});

  @override
  State<AuthSettingsView> createState() => _AuthSettingsViewState();
}

class _AuthSettingsViewState extends State<AuthSettingsView> {
  late final RemoteConfigController<AuthConfigFields> _remoteConfigController;
  late final AuthConfigCubit configBloc;
  late final void Function() _removeServerConfigListener;

  @override
  void initState() {
    super.initState();
    _remoteConfigController = context.read();
    final account = context.read<PhylumAccount>();
    configBloc = AuthConfigCubit(
      remote: _remoteConfigController.config!,
      createCryptConfigCubit: (remote) =>
          CryptSettingsCubit(account: account, remote: remote),
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
      child: MaterialAuthSettingsView(bloc: configBloc), //TODO #uilibrary
    );
  }
}
