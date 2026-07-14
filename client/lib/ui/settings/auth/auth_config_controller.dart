import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';
import 'package:provider/provider.dart';

class AuthConfigState {
  final bool loading;
  final String? error;
  final AuthConfig? config;

  const AuthConfigState({this.loading = false, this.error, this.config});
}

class AuthConfigController extends RemoteConfigController<AuthConfig> {
  late final ApiClient<PhylumAccount> _apiClient;

  AuthConfigController(BuildContext context)
    : super(
        context,
        endpoint: '/api/v1/admin/config/auth/read',
        parseConfig: AuthConfig.fromMap,
      ) {
    _apiClient = context.read<PhylumAccount>().apiClient;
  }

  set passwordlessLoginEnabled(bool enabled) {
    // state = AuthConfigState(
    //   loading: state.loading,
    //   error: state.error,
    //   config: state.config?.copyWith(passwordlessLoginEnabled: enabled),
    // );
  }

  set passwordConfig(PasswordConfig config) {
    // state = AuthConfigState(
    //   loading: state.loading,
    //   error: state.error,
    //   config: state.config?.copyWith(passwordConfig: config),
    // );
  }

  void addOpenIDConfig(OpenIDConfig config) {
    // state = AuthConfigState(
    //   loading: state.loading,
    //   error: state.error,
    //   config: state.config?.copyWith(
    //     openIdConfigs: [
    //       ...state.config!.openIdConfigs,
    //       config,
    //     ].toList(growable: false),
    //   ),
    // );
  }

  void replaceOpenIDConfig(OpenIDConfig old, OpenIDConfig config) {
    // state = AuthConfigState(
    //   loading: state.loading,
    //   error: state.error,
    //   config: state.config?.copyWith(
    //     openIdConfigs: state.config!.openIdConfigs
    //         .map((e) => e == old ? config : e)
    //         .toList(growable: false),
    //   ),
    // );
  }

  void removeOpenIDConfig(OpenIDConfig config) {
    // state = AuthConfigState(
    //   loading: state.loading,
    //   error: state.error,
    //   config: state.config?.copyWith(
    //     openIdConfigs: state.config!.openIdConfigs
    //         .where((e) => e.id != config.id)
    //         .toList(growable: false),
    //   ),
    // );
  }
}
