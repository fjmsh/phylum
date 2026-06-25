import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/mail_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

part 'config_read_request.dart';
part 'config_response.dart';

class MailConfigState {
  final bool loading;
  final String? error;
  final MailConfig? config;

  const MailConfigState({this.loading = false, this.error, this.config});
}

class MailConfigController extends StateNotifier<MailConfigState> {
  late final ApiClient<PhylumAccount> _apiClient;

  MailConfigController(BuildContext context) : super(const MailConfigState()) {
    _apiClient = context.read<PhylumAccount>().apiClient;
  }

  void fetch() async {
    if (state.loading) return;
    final result = await _apiClient.sendRequest(_ConfigReadRequest());
    if (result is _ConfigResponse) {
      state = MailConfigState(config: result.config);
    } else {
      state = MailConfigState(error: result.description);
    }
  }

  void maybeFetch() {
    if (state.config == null) {
      fetch();
    }
  }
}
