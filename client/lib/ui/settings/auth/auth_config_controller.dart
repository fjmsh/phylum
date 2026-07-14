import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/util/request.dart';
import 'package:provider/provider.dart';
import 'package:uri/uri.dart';

import 'api/update_request.dart';

class AuthConfigFormState {
  final AuthConfig config;
  final bool mailEnabled;
  final bool requestInFlight;

  AuthConfigFormState({
    required this.config,
    required this.mailEnabled,
    required this.requestInFlight,
  });

  AuthConfigFormState copyWith({
    AuthConfig? config,
    bool? mailEnabled,
    bool? requestInFlight,
  }) {
    return AuthConfigFormState(
      config: config ?? this.config,
      mailEnabled: mailEnabled ?? this.mailEnabled,
      requestInFlight: requestInFlight ?? this.requestInFlight,
    );
  }

  @override
  String toString() =>
      'AuthConfigFormState(config: $config, mailEnabled: $mailEnabled, requestInFlight: $requestInFlight)';

  @override
  bool operator ==(covariant AuthConfigFormState other) {
    if (identical(this, other)) return true;

    final result =
        other.config == config &&
        other.mailEnabled == mailEnabled &&
        other.requestInFlight == requestInFlight;
    return result;
  }

  @override
  int get hashCode =>
      config.hashCode ^ mailEnabled.hashCode ^ requestInFlight.hashCode;
}

class AuthConfigFormCubit extends Cubit<AuthConfigFormState> {
  final AuthConfig _initialConfig;
  late final ApiClient<PhylumAccount> _apiClient;
  late final void Function() _removeConfigListener;

  AuthConfigFormCubit(BuildContext context, this._initialConfig)
    : super(
        AuthConfigFormState(
          config: _initialConfig,
          mailEnabled: false,
          requestInFlight: false,
        ),
      ) {
    _removeConfigListener = context
        .read<PhylumAccount>()
        .configNotifier
        .addListener((config) {
          if (config.mail != state.mailEnabled) {
            emit(state.copyWith(mailEnabled: config.mail));
          }
        });
    _apiClient = context.read<PhylumAccount>().apiClient;
  }

  @override
  void onChange(Change<AuthConfigFormState> change) {
    super.onChange(change);
  }

  @override
  Future<void> close() async {
    _removeConfigListener();
    await super.close();
  }

  set passwordlessLoginEnabled(bool enabled) {
    emit(
      state.copyWith(
        config: state.config.copyWith(passwordlessLoginEnabled: enabled),
      ),
    );
  }

  set passwordConfig(PasswordConfig config) {
    emit(state.copyWith(config: state.config.copyWith(passwordConfig: config)));
  }

  void addOpenIDConfig(OpenIDConfig config) {
    emit(
      state.copyWith(
        config: state.config.copyWith(
          openIdConfigs: [
            ...state.config.openIdConfigs,
            config,
          ].toList(growable: false),
        ),
      ),
    );
  }

  void replaceOpenIDConfig(OpenIDConfig old, OpenIDConfig config) {
    emit(
      state.copyWith(
        config: state.config.copyWith(
          openIdConfigs: state.config.openIdConfigs
              .map((e) => e == old ? config : e)
              .toList(growable: false),
        ),
      ),
    );
  }

  void removeOpenIDConfig(OpenIDConfig config) {
    emit(
      state.copyWith(
        config: state.config.copyWith(
          openIdConfigs: state.config.openIdConfigs
              .where((e) => e.id != config.id)
              .toList(growable: false),
        ),
      ),
    );
  }

  Future<void> save() async {
    if (state.requestInFlight) return;

    final config = state.config;
    if (!config.passwordLoginEnabled &&
        !config.passwordlessLoginEnabled &&
        config.openIdConfigs.isEmpty) {
      // showAlertDialog(
      //   context,
      //   message: 'You must set up at least 1 login method',
      // );
      return;
    }

    emit(state.copyWith(requestInFlight: true));
    final result = await _apiClient.sendRequest(
      UpdateAuthConfigRequest(old: _initialConfig, config: config),
    );

    emit(state.copyWith(requestInFlight: false));

    if (result is ApiSuccessResponse) {
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('Auth Config Updated'),
      //     duration: Duration(seconds: 2),
      //   ),
      // );
    } else {
      // showAlertDialog(
      //   context,
      //   title: 'Failed to update Auth Config',
      //   message: result.description,
      // );
    }
  }

  Future<KDFTestResult> testArgon2Params(
    int memory,
    int iterations,
    int parallelism,
  ) async {
    return testParams(
      endpoint: '/api/v1/setup/auth/test_argon2_params',
      params: {
        "memory": memory.toString(),
        "iterations": iterations.toString(),
        "parallelism": parallelism.toString(),
      },
    );
  }

  Future<KDFTestResult> testPbkdf2Params(
    HashFunction hash,
    int iterations,
  ) async {
    return testParams(
      endpoint: '/api/v1/setup/auth/test_pbkdf2_params',
      params: {"function": hash.name, "iterations": iterations.toString()},
    );
  }

  Future<KDFTestResult> testParams({
    required String endpoint,
    required Map<String, String> params,
  }) async {
    final builder = UriBuilder.fromUri(_apiClient.serverUrl);
    builder.path = '${builder.path}$endpoint';
    builder.queryParameters = params;
    final request = Request('get', builder.build());

    final response = await sendRequest(request);
    switch (response) {
      case ServerOffline():
        return KDFTestFailure(title: response.title);
      case ClientError() || ErrorResponse():
        return KDFTestFailure(title: response.title, details: response.details);
      case SuccessResponse():
        final responseMap = (jsonDecode(response.responseString) as Map)
            .cast<String, dynamic>();

        if (responseMap["success"]) {
          return KDFTestSuccess(
            duration: Duration(microseconds: responseMap["time"]),
          );
        } else {
          return KDFTestFailure(
            title: 'Failed to test params',
            details: responseMap['error'],
          );
        }
    }
  }
}

sealed class KDFTestResult {
  const KDFTestResult();
}

class KDFTestFailure extends KDFTestResult {
  final String title;

  final String? details;

  const KDFTestFailure({required this.title, this.details});
}

class KDFTestSuccess extends KDFTestResult {
  final Duration duration;

  const KDFTestSuccess({required this.duration});
}
