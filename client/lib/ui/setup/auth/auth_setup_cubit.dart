import 'dart:convert';

import 'package:http/http.dart';
import 'package:phylum/ui/config/auth/auth_config_cubit.dart';
import 'package:phylum/ui/config/config_check_result.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class AuthSetupCubit extends AuthConfigCubit {
  final String _instanceUrl;

  AuthSetupCubit({
    required this._instanceUrl,
    required super.remote,
    required super.createCryptConfigCubit,
  });

  // Future<ConfigCheckResult> checkConfig() async {
  //   if (!state.passwordlessLoginEnabled &&
  //       !passwordBloc.state.enabled &&
  //       state.openIdConfigs.isEmpty) {
  //     return ConfigInvalid(error: 'You must enable at least 1 login method');
  //   }
  //   final config = validateConfig();
  //   if (config == null) {
  //     return ConfigInvalid();
  //   }
  //   return ConfigCheckSuccess(config: config);
  // }

  Future<ConfigCheckResult> checkConfig() async {
    final config = validateConfig();
    if (config == null) return ConfigInvalid();

    final builder = UriBuilder.fromUri(Uri.parse(_instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/auth/validate';
    final request = Request('post', builder.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(config);

    final result = await sendRequest(request);

    if (result is SuccessResponse) {
      final responseMap = (jsonDecode(result.responseString) as Map)
          .cast<String, dynamic>();

      final error = (responseMap['error'] as Map?)?.cast<String, dynamic>();
      final warning = (responseMap['warning'] as Map?)?.cast<String, dynamic>();
      if (error != null) {
        return ConfigCheckError(
          config: config,
          title: error['msg'],
          message: error['details'],
        );
      } else if (warning != null) {
        return ConfigCheckWarning(config: config, code: warning['code']);
      }
      return ConfigCheckSuccess(config: config);
    } else {
      return ConfigCheckError(config: config, message: result.toString());
    }
  }
}
