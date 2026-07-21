import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

part 'config_read_request.dart';
part 'config_response.dart';
part 'config_update_request.dart';

abstract class Config {
  Map<String, dynamic> toMap();
}

sealed class RemoteConfigState<T extends Config> {
  const RemoteConfigState();
}

class RemoteConfigStateWaiting<T extends Config> extends RemoteConfigState<T> {
  final String? error;

  const RemoteConfigStateWaiting({this.error});
}

class RemoteConfigStateLoading<T extends Config> extends RemoteConfigState<T> {
  const RemoteConfigStateLoading();
}

class RemoteConfigStateLoaded<T extends Config> extends RemoteConfigState<T> {
  final T config;
  final DateTime timestamp;
  final bool saving;

  RemoteConfigStateLoaded({
    required this.config,
    required this.timestamp,
    required this.saving,
  });
}

class RemoteConfigController<T extends Config>
    extends StateNotifier<RemoteConfigState<T>> {
  final String _baseRoute;
  final T Function(Map<String, dynamic>) _parseConfig;
  late final ApiClient<PhylumAccount> _apiClient;

  RemoteConfigController(
    BuildContext context, {
    required this._baseRoute,
    required this._parseConfig,
  }) : super(const RemoteConfigStateWaiting()) {
    _apiClient = context.read<PhylumAccount>().apiClient;
  }

  T? get config => (state is RemoteConfigStateLoaded<T>)
      ? (state as RemoteConfigStateLoaded<T>).config
      : null;

  void fetch() async {
    if (state is RemoteConfigStateLoading) return;
    state = const RemoteConfigStateLoading();
    final result = await _apiClient.sendRequest(
      _ConfigReadRequest(baseRoute: _baseRoute, parseConfig: _parseConfig),
    );
    if (result is _ConfigResponse) {
      state = RemoteConfigStateLoaded(
        config: result.config,
        timestamp: DateTime.now(),
        saving: false,
      );
    } else {
      state = RemoteConfigStateWaiting(error: result.description);
    }
  }

  void maybeFetch() {
    if (state is RemoteConfigStateWaiting) {
      fetch();
    }
  }

  Future<String?> save({required T config}) async {
    final state = this.state;
    if (state is! RemoteConfigStateLoaded<T>) return null;
    if (state.saving) return null;

    this.state = RemoteConfigStateLoaded<T>(
      config: state.config,
      timestamp: state.timestamp,
      saving: true,
    );
    final result = await _apiClient.sendRequest(
      _ConfigUpdateRequest(baseRoute: _baseRoute, config: config),
    );

    this.state = result is ApiSuccessResponse
        ? RemoteConfigStateLoaded<T>(
            config: config,
            timestamp: DateTime.now(),
            saving: true,
          )
        : state;

    return (result is ApiSuccessResponse) ? null : result.description;
  }
}
