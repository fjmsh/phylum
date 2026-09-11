import 'dart:convert';

import 'package:http/http.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config_cubit.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class CryptSetupCubit extends CryptConfigCubit {
  final String _instanceUrl;

  CryptSetupCubit({required super.remote, required this._instanceUrl});

  @override
  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  }) async {
    final builder = UriBuilder.fromUri(Uri.parse(_instanceUrl));
    builder.path =
        '${builder.path}/api/v1/setup/auth/test/${switch (kdf) {
          CryptKDF.argon2 => 'argon2',
          CryptKDF.pbkdf2 => 'pbkdf2',
        }}';
    final request = Request('POST', builder.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(params);

    final result = await sendRequest(request);

    if (result is SuccessResponse) {
      final responseMap = (jsonDecode(result.responseString) as Map)
          .cast<String, dynamic>();

      final error = responseMap['error'];
      if (error != null) {
        return KDFTestFailure(title: 'Error', details: error);
      }
      return KDFTestSuccess(
        duration: Duration(microseconds: responseMap["time"]),
      );
    } else {
      return KDFTestFailure(title: result.toString());
    }
  }
}
