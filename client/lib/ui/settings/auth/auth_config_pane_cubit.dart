import 'package:bloc/bloc.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/settings/auth/api/update_request.dart';

import 'api/test_params_request.dart';
import 'form/auth_config_form_cubit.dart';

class AuthConfigPaneCubit extends AuthConfigFormCubit {
  late ApiClient<PhylumAccount> _apiClient;

  AuthConfigPaneCubit(
    PhylumAccount account, {
    required AuthConfig initialConfig,
  }) : super(account, initialConfig: initialConfig) {
    _apiClient = account.apiClient;
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
  final AuthConfig _initialConfig;
  final void Function(AuthConfig) _onConfigUpdated;

  AuthConfigSaveCubit({
    required PhylumAccount account,
    required this._initialConfig,
    required this._onConfigUpdated,
  }) : super(AuthConfigSaveState(requestInFlight: false)) {
    _apiClient = account.apiClient;
  }

  Future<String?> save(AuthConfig config) async {
    if (state.requestInFlight) return null;

    if (!config.passwordLoginEnabled &&
        !config.passwordlessLoginEnabled &&
        config.openIdConfigs.isEmpty) {
      return 'You must configure at least 1 login method';
    }

    emit(AuthConfigSaveState(requestInFlight: true));
    final result = await _apiClient.sendRequest(
      UpdateAuthConfigRequest(old: _initialConfig, config: config),
    );

    emit(AuthConfigSaveState(requestInFlight: false));

    _onConfigUpdated(config);

    return (result is ApiSuccessResponse) ? null : result.description;
  }
}
