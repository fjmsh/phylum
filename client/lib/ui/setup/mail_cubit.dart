import 'dart:convert';

import 'package:http/http.dart';
import 'package:phylum/ui/settings/mail/form/mail_config_form_cubit.dart';
import 'package:phylum/ui/setup/config_check_result.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class MailConfigSetupCubit extends MailConfigFormCubit {
  final String _instanceUrl;

  MailConfigSetupCubit({
    required this._instanceUrl,
    required super.remoteConfig,
  }) : super(instanceUrl: _instanceUrl);

  Future<ConfigCheckResult> checkConfig() async {
    final config = validateConfig();
    if (config == null) return ConfigInvalid();

    final builder = UriBuilder.fromUri(Uri.parse(_instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/mail/validate';
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
