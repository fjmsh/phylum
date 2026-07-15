import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/responses/responses.dart';
import 'package:phylum/ui/settings/auth/api/test_params_request.dart';
import 'package:provider/provider.dart';

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
  final void Function(AuthConfig) _onConfigUpdated;

  AuthConfigFormCubit(
    BuildContext context, {
    required this._initialConfig,
    required this._onConfigUpdated,
  }) : super(
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

  Future<String?> save() async {
    if (state.requestInFlight) return null;

    final config = state.config;
    if (!config.passwordLoginEnabled &&
        !config.passwordlessLoginEnabled &&
        config.openIdConfigs.isEmpty) {
      return 'You must configure at least 1 login method';
    }

    emit(state.copyWith(requestInFlight: true));
    final result = await _apiClient.sendRequest(
      UpdateAuthConfigRequest(old: _initialConfig, config: config),
    );

    emit(state.copyWith(requestInFlight: false));

    _onConfigUpdated(config);

    return (result is ApiSuccessResponse) ? null : result.description;
  }

  Future<KDFTestResult> testArgon2Params(
    int memory,
    int iterations,
    int parallelism,
  ) async {
    return testParams(
      kdf: .argon2,
      params: {
        "memory": memory,
        "iterations": iterations,
        "parallelism": parallelism,
      },
    );
  }

  Future<KDFTestResult> testPbkdf2Params(
    HashFunction hash,
    int iterations,
  ) async {
    return testParams(
      kdf: .pbkdf2,
      params: {"function": hash.name, "iterations": iterations},
    );
  }

  Future<KDFTestResult> testParams({
    required CryptKDF kdf,
    required Map<String, dynamic> params,
  }) async {
    final result = await _apiClient.sendRequest(
      TestParamsRequest(kdf: kdf, params: params),
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
