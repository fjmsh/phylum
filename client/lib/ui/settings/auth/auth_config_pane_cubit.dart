import 'package:bloc/bloc.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/settings/auth/api/update_request.dart';
import 'package:phylum/ui/settings/config/remote_config_controller.dart';

import 'api/test_params_request.dart';
import 'form/auth_config_form_cubit.dart';

class AuthConfigPaneCubit extends AuthConfigFormCubit {
  late ApiClient<PhylumAccount> _apiClient;
  final RemoteConfigController<AuthConfig> _remoteConfigController;

  AuthConfigPaneCubit({
    required PhylumAccount account,
    required this._remoteConfigController,
  }) : super(
         initialConfig: _remoteConfigController.config ?? AuthConfig.defaults(),
       ) {
    _apiClient = account.apiClient;
  }

  void reset() {
    emit(
      state.copyWith(
        config: _remoteConfigController.config ?? AuthConfig.defaults(),
      ),
    );
  }

  @override
  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  }) async {
    final result = await _apiClient.sendRequest(
      TestParamsRequest(kdf: kdf, params: params),
    );

    switch (result) {
      case ApiUnreachableError():
        return KDFTestFailure(title: 'Server Unreachable');
      case ApiClientError():
        return KDFTestFailure(
          title: 'Client Error',
          details: result.ex.toString(),
        );
      case PhylumApiErrorResponse():
        return KDFTestFailure(title: 'Server Error', details: result.message);
      case TestParamsResponse():
        if (result.duration != null) {
          return KDFTestSuccess(duration: result.duration!);
        }
        return KDFTestFailure(
          title: 'Failed to test params',
          details: result.error,
        );
      case ApiSuccessResponse<PhylumAccount>():
        throw UnimplementedError();
      case ApiErrorResponse<PhylumAccount>():
        throw UnimplementedError();
    }
  }
}

class AuthConfigSaveState {
  final bool requestInFlight;

  const AuthConfigSaveState({required this.requestInFlight});
}

class AuthConfigSaveCubit extends Cubit<AuthConfigSaveState> {
  late final ApiClient _apiClient;
  final RemoteConfigController<AuthConfig> _remoteConfigController;

  AuthConfigSaveCubit({
    required PhylumAccount account,
    required this._remoteConfigController,
  }) : super(AuthConfigSaveState(requestInFlight: false)) {
    _apiClient = account.apiClient;
  }

  Future<String?> save({required AuthConfig config}) async {
    if (state.requestInFlight) return null;

    if (!config.passwordLoginEnabled &&
        !config.passwordlessLoginEnabled &&
        config.openIdConfigs.isEmpty) {
      return 'You must configure at least 1 login method';
    }

    emit(AuthConfigSaveState(requestInFlight: true));
    final result = await _apiClient.sendRequest(
      UpdateAuthConfigRequest(
        old: _remoteConfigController.config ?? AuthConfig.defaults(),
        config: config,
      ),
    );

    emit(AuthConfigSaveState(requestInFlight: false));

    _remoteConfigController.update(config);

    return (result is ApiSuccessResponse) ? null : result.description;
  }
}
