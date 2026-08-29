import 'dart:convert';

import 'package:http/http.dart';
import 'package:phylum/ui/settings/config/config.dart';
import 'package:phylum/ui/settings/mail/form/mail_config_form_cubit.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class MailConfigSetupCubit extends MailConfigFormCubit {
  final String _instanceUrl;
  final RemoteConfig<MailConfigFields> _remoteConfig;

  MailConfigSetupCubit({
    required this._instanceUrl,
    required this._remoteConfig,
  }) : super(remoteConfig: _remoteConfig, instanceUrl: _instanceUrl);

  Future<String?> checkConfig(LocalConfig<MailConfigFields> local) async {
    if (!local.getValue(MailConfigFields.fieldEnabled)) {
      return null;
    }

    final builder = UriBuilder.fromUri(Uri.parse(_instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/mail/validate';
    final request = Request('post', builder.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(local.toMap(_remoteConfig));

    final result = await sendRequest(request);
    if (result is SuccessResponse) {
      final responseMap = (jsonDecode(result.responseString) as Map)
          .cast<String, dynamic>();
      return responseMap['error'];
    }
    return result.toString();
  }
}
