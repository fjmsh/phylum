import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

part 'api/config_read_request.dart';
part 'api/config_response.dart';

class AuthConfigState {
  final bool loading;
  final String? error;
  final AuthConfig? config;

  const AuthConfigState({this.loading = false, this.error, this.config});
}

class AuthConfigController extends StateNotifier<AuthConfigState> {
  late final ApiClient<PhylumAccount> _apiClient;

  AuthConfigController(BuildContext context) : super(const AuthConfigState()) {
    _apiClient = context.read<PhylumAccount>().apiClient;
  }

  void fetch() async {
    if (state.loading) return;
    state = AuthConfigState(loading: true);
    final result = await _apiClient.sendRequest(_ConfigReadRequest());
    if (result is _ConfigResponse) {
      state = AuthConfigState(config: result.config);
    } else {
      state = AuthConfigState(error: result.description);
    }
  }

  void maybeFetch() {
    if (state.config == null) {
      fetch();
    }
  }

  set passwordlessLoginEnabled(bool enabled) {
    state = AuthConfigState(
      loading: state.loading,
      error: state.error,
      config: state.config?.copyWith(passwordlessLoginEnabled: enabled),
    );
  }

  set passwordConfig(PasswordConfig config) {
    state = AuthConfigState(
      loading: state.loading,
      error: state.error,
      config: state.config?.copyWith(passwordConfig: config),
    );
  }

  void addOpenIDConfig(OpenIDConfig config) {
    state = AuthConfigState(
      loading: state.loading,
      error: state.error,
      config: state.config?.copyWith(
        openIdConfigs: [
          ...state.config!.openIdConfigs,
          config,
        ].toList(growable: false),
      ),
    );
  }

  void replaceOpenIDConfig(OpenIDConfig old, OpenIDConfig config) {
    state = AuthConfigState(
      loading: state.loading,
      error: state.error,
      config: state.config?.copyWith(
        openIdConfigs: state.config!.openIdConfigs
            .map((e) => e == old ? config : e)
            .toList(growable: false),
      ),
    );
  }

  void removeOpenIDConfig(OpenIDConfig config) {
    state = AuthConfigState(
      loading: state.loading,
      error: state.error,
      config: state.config?.copyWith(
        openIdConfigs: state.config!.openIdConfigs
            .where((e) => e.id != config.id)
            .toList(growable: false),
      ),
    );
  }
}
