import 'package:bloc/bloc.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/config/config.dart';

class AuthConfigFormState {
  final AuthConfig config;
  final bool mailEnabled;

  AuthConfigFormState({required this.config, required this.mailEnabled});

  factory AuthConfigFormState.createFromRemoteConfig({
    required RemoteConfig<AuthConfigFields> config,
    required bool mailEnabled,
  }) {
    return AuthConfigFormState(
      config: AuthConfig.defaults(),
      mailEnabled: mailEnabled,
    );
  }

  AuthConfigFormState copyWith({AuthConfig? config, bool? mailEnabled}) {
    return AuthConfigFormState(
      config: config ?? this.config,
      mailEnabled: mailEnabled ?? this.mailEnabled,
    );
  }

  @override
  String toString() =>
      'AuthConfigFormState(config: $config, mailEnabled: $mailEnabled)';

  @override
  bool operator ==(covariant AuthConfigFormState other) {
    if (identical(this, other)) return true;

    return other.config == config && other.mailEnabled == mailEnabled;
  }

  @override
  int get hashCode => config.hashCode ^ mailEnabled.hashCode;
}

abstract class AuthConfigFormCubit extends Cubit<AuthConfigFormState> {
  AuthConfigFormCubit({required RemoteConfig<AuthConfigFields> remoteConfig})
    : super(
        AuthConfigFormState.createFromRemoteConfig(
          config: remoteConfig,
          mailEnabled: false,
        ),
      );

  void reset(RemoteConfig<AuthConfigFields> config) {
    emit(
      AuthConfigFormState.createFromRemoteConfig(
        config: config,
        mailEnabled: state.mailEnabled,
      ),
    );
  }

  set mailEnabled(bool enabled) {
    emit(state.copyWith(mailEnabled: enabled));
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
    final re = RegExp(r'[^a-z0-9]+');
    final originalId = config.name.toLowerCase().replaceAll(re, '-');
    String id = originalId;
    int i = 2;
    while (state.config.openIdConfigs.containsKey(id)) {
      id = '$originalId-$i';
      i++;
    }
    final configs = Map.of(state.config.openIdConfigs);
    configs[id] = config;
    emit(state.copyWith(config: state.config.copyWith(openIdConfigs: configs)));
  }

  void replaceOpenIDConfig(String id, OpenIDConfig config) {
    final configs = Map.of(state.config.openIdConfigs);
    configs[id] = config;
    emit(state.copyWith(config: state.config.copyWith(openIdConfigs: configs)));
  }

  void removeOpenIDConfig(String id) {
    final configs = Map.of(state.config.openIdConfigs);
    configs.remove(id);
    emit(state.copyWith(config: state.config.copyWith(openIdConfigs: configs)));
  }

  LocalConfig<AuthConfigFields>? validate() {
    return null;
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
  });
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
