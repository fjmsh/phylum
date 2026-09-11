import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config_cubit.dart';

import 'api/test_kdf_params_request.dart';

class CryptSettingsCubit extends CryptConfigCubit {
  final ApiClient<PhylumAccount> _apiClient;
  CryptSettingsCubit({required PhylumAccount account, required super.remote})
    : _apiClient = account.apiClient;

  @override
  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  }) async {
    final result = await _apiClient.sendRequest(
      TestKDFParamsRequest(kdf: kdf, params: params),
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
