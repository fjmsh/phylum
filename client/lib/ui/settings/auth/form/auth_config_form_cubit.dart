import 'package:bloc/bloc.dart';
import 'package:phylum/libphylum/config/auth_config.dart';
import 'package:phylum/libphylum/phylum_account.dart';

class AuthConfigFormState {
  final AuthConfig config;
  final bool mailEnabled;

  AuthConfigFormState({required this.config, required this.mailEnabled});

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
  late final void Function() _removeConfigListener;

  AuthConfigFormCubit(
    PhylumAccount account, {
    required AuthConfig initialConfig,
  }) : super(AuthConfigFormState(config: initialConfig, mailEnabled: false)) {
    _removeConfigListener = account.configNotifier.addListener((config) {
      if (config.mail != state.mailEnabled) {
        emit(state.copyWith(mailEnabled: config.mail));
      }
    });
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
