import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:phylum/ui/settings/config/local_config_updates.dart';
import 'package:phylum/ui/settings/config/remote_config.dart';
import 'package:phylum/ui/settings/mail/form/mail_config_form.dart';
import 'package:phylum/ui/settings/mail/form/mail_config_form_cubit.dart';
import 'package:phylum/ui/settings/mail/mail_config.dart';
import 'package:phylum/util/dialogs.dart';
import 'package:phylum/util/request.dart';
import 'package:uri/uri.dart';

class SetupMailFragment extends StatelessWidget {
  final MailConfigSetupCubit _bloc;
  final formKey = GlobalKey<FormState>();
  final void Function() onPrevPress;
  final void Function() onNextPress;

  SetupMailFragment({
    super.key,
    required this._bloc,
    required this.onPrevPress,
    required this.onNextPress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: MailConfigForm(
              bloc: _bloc,
              onFormSubmitted: validateAndNext,
            ),
          ),
        ),
        TextButtonTheme(
          data: TextButtonThemeData(
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(onPressed: onPrevPress, child: Text('PREV')),
              TextButton(
                onPressed: () => validateAndNext(context),
                child: Text('NEXT'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> validateAndNext(BuildContext context) async {
    final config = _bloc.validate();
    if (config == null) return;

    if (!config.get(MailConfigFields.fieldEnabled)) {
      onNextPress();
      return;
    }
    final nav = Navigator.of(context);
    showProgressDialog(context, message: 'Checking Email Config');
    final error = await _bloc.checkConfig(config);
    nav.pop();
    if (error == null) {
      onNextPress();
    } else {
      if (!context.mounted) return;
      final remain = await showAlertDialog(
        context,
        title: 'Config Check Failed',
        message: error,
        negativeText: 'Continue Anyway',
      );
      if (remain == false) {
        onNextPress();
      }
    }
  }
}

class MailConfigSetupCubit extends MailConfigFormCubit {
  final RemoteConfig<MailConfigFields> _remoteConfig;
  final String instanceUrl;

  MailConfigSetupCubit({required this._remoteConfig, required this.instanceUrl})
    : super(remoteConfig: _remoteConfig, instanceUrl: instanceUrl);

  Future<String?> checkConfig(
    LocalConfigUpdates<MailConfigFields> config,
  ) async {
    if (!config.get(MailConfigFields.fieldEnabled)) {
      return null;
    }

    final builder = UriBuilder.fromUri(Uri.parse(instanceUrl));
    builder.path = '${builder.path}/api/v1/setup/mail/validate';
    final request = Request('post', builder.build());
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode(config.toMapDiff());
    if (4 < 5) {
      return request.body;
    }

    final result = await sendRequest(request);
    if (result is SuccessResponse) {
      final responseMap = (jsonDecode(result.responseString) as Map)
          .cast<String, dynamic>();
      return responseMap['error'];
    }
    return result.toString();
  }
}
