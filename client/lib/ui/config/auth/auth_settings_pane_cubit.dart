import 'package:offtheline/offtheline.dart';
import 'package:phylum/ui/config/auth/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';

import 'api/test_params_request.dart';
import 'form/auth_config_form_cubit.dart';

class AuthConfigPaneCubit extends AuthConfigCubit {
  final ApiClient<PhylumAccount> _apiClient;

  AuthConfigPaneCubit({required PhylumAccount account, required super.remote})
    : _apiClient = account.apiClient;

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
