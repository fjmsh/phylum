import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

part 'config_read_request.dart';
part 'config_response.dart';

class RemoteConfigState<T> {
  final bool loading;
  final String? error;
  final T? config;

  const RemoteConfigState({this.loading = false, this.error, this.config});
}

class RemoteConfigController<T> extends StateNotifier<RemoteConfigState<T>> {
  final String _endpoint;
  final T Function(Map<String, dynamic>) _parseConfig;
  late final ApiClient<PhylumAccount> _apiClient;

  RemoteConfigController(
    BuildContext context, {
    required this._endpoint,
    required this._parseConfig,
  }) : super(const RemoteConfigState()) {
    _apiClient = context.read<PhylumAccount>().apiClient;
  }

  T? get config => state.config;

  void fetch() async {
    if (state.loading) return;
    state = RemoteConfigState(loading: true);
    final result = await _apiClient.sendRequest(
      _ConfigReadRequest(endpoint: _endpoint, parseConfig: _parseConfig),
    );
    if (result is _ConfigResponse) {
      state = RemoteConfigState(config: result.config);
    } else {
      state = RemoteConfigState(error: result.description);
    }
  }

  void maybeFetch() {
    if (state.config == null) {
      fetch();
    }
  }

  void update(T config) {
    state = RemoteConfigState(
      loading: state.loading,
      error: state.error,
      config: config,
    );
  }
}
