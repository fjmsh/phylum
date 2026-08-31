import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:phylum/ui/settings/auth/auth_config.dart';
import 'package:phylum/ui/settings/auth/form/crypt_config_cubit.dart';
import 'package:phylum/ui/settings/auth/form/ldap_config_cubit.dart';
import 'package:phylum/ui/settings/auth/form/openid_config_cubit.dart';
import 'package:phylum/ui/settings/config/config.dart';
import 'package:phylum/ui/setup/config_check_result.dart';

class AuthConfigFormState {
  final bool mailEnabled;
  final bool passwordlessLoginEnabled;
  final PasswordBackend passwordBackend;
  final Map<String, OpenIDConfig> openIdConfigs;

  AuthConfigFormState({
    required this.mailEnabled,
    required this.passwordlessLoginEnabled,
    required this.passwordBackend,
    required this.openIdConfigs,
  });

  factory AuthConfigFormState.createFromRemoteConfig({
    required bool mailEnabled,
    required RemoteConfig<AuthConfigFields> config,
  }) {
    final openIdConfigs = config
        .getMap(AuthConfigFields.fieldOpenidClients)
        .map((id, config) {
          return MapEntry(id, OpenIDConfig.createFromConfig(config));
        });
    return AuthConfigFormState(
      mailEnabled: mailEnabled,
      passwordlessLoginEnabled: config.getValue(
        AuthConfigFields.fieldMagicLinks,
      ),
      passwordBackend: config.getValue(AuthConfigFields.fieldPasswordBackend),
      openIdConfigs: openIdConfigs,
    );
  }

  AuthConfigFormState copyWith({
    bool? mailEnabled,
    bool? passwordlessLoginEnabled,
    PasswordBackend? passwordBackend,
    Map<String, OpenIDConfig>? openIdConfigs,
  }) => AuthConfigFormState(
    mailEnabled: mailEnabled ?? this.mailEnabled,
    passwordlessLoginEnabled:
        passwordlessLoginEnabled ?? this.passwordlessLoginEnabled,
    passwordBackend: passwordBackend ?? this.passwordBackend,
    openIdConfigs: openIdConfigs ?? this.openIdConfigs,
  );

  @override
  String toString() =>
      'AuthConfigFormState('
      'mailEnabled: $mailEnabled, '
      'passwordlessLoginEnabled: $passwordlessLoginEnabled'
      'passwordBackend: $passwordBackend,'
      'openIdConfigs: $openIdConfigs,'
      ')';

  @override
  bool operator ==(covariant AuthConfigFormState other) {
    if (identical(this, other)) return true;

    return other.mailEnabled == mailEnabled &&
        other.passwordlessLoginEnabled == passwordlessLoginEnabled &&
        other.passwordBackend == passwordBackend &&
        const MapEquality().equals(other.openIdConfigs, openIdConfigs);
  }

  @override
  int get hashCode =>
      mailEnabled.hashCode & passwordlessLoginEnabled.hashCode ^
      passwordBackend.hashCode ^
      const MapEquality().hash(openIdConfigs);
}

abstract class AuthConfigFormCubit extends Cubit<AuthConfigFormState> {
  RemoteConfig<AuthConfigFields> _remote;
  late final cryptBloc = CryptConfigCubit(remote: _remote);
  late final LdapConfigCubit ldapBloc = LdapConfigCubit(remote: _remote);

  AuthConfigFormCubit({required this._remote})
    : super(
        AuthConfigFormState.createFromRemoteConfig(
          config: _remote,
          mailEnabled: false,
        ),
      );

  void reset(RemoteConfig<AuthConfigFields> remote) {
    _remote = remote;
    emit(
      AuthConfigFormState.createFromRemoteConfig(
        config: remote,
        mailEnabled: state.mailEnabled,
      ),
    );
    cryptBloc.reset(remote);
    ldapBloc.reset(remote);
  }

  set mailEnabled(bool val) {
    emit(state.copyWith(mailEnabled: val));
  }

  set passwordlessLoginEnabled(bool val) {
    emit(state.copyWith(passwordlessLoginEnabled: val));
  }

  set passwordBackend(PasswordBackend val) {
    emit(state.copyWith(passwordBackend: val));
  }

  void addOpenIDConfig(OpenIDConfig config) {
    final re = RegExp(r'[^a-z0-9]+');
    final originalId = config.name.toLowerCase().replaceAll(re, '-');
    String id = originalId;
    int i = 2;
    while (state.openIdConfigs.containsKey(id)) {
      id = '$originalId-$i';
      i++;
    }
    final configs = Map.of(state.openIdConfigs);
    configs[id] = config;
    emit(state.copyWith(openIdConfigs: configs));
  }

  void replaceOpenIDConfig(String id, OpenIDConfig config) {
    final configs = Map.of(state.openIdConfigs);
    configs[id] = config;
    emit(state.copyWith(openIdConfigs: configs));
  }

  void removeOpenIDConfig(String id) {
    final configs = Map.of(state.openIdConfigs);
    configs.remove(id);
    emit(state.copyWith(openIdConfigs: configs));
  }

  Map<String, dynamic>? validateConfig() {
    final config = LocalConfig<AuthConfigFields>()
      ..setValue(
        AuthConfigFields.fieldMagicLinks,
        state.passwordlessLoginEnabled,
      )
      ..setValue(AuthConfigFields.fieldPasswordBackend, state.passwordBackend);
    switch (state.passwordBackend) {
      case PasswordBackend.crypt:
        final cryptConfig = cryptBloc.validate();
        if (cryptConfig == null) {
          return null;
        }
        config.values.addAll(cryptConfig.values);
        break;
      case PasswordBackend.ldap:
        final ldapConfig = ldapBloc.validate();
        if (ldapConfig == null) {
          return null;
        }
        config.values.addAll(ldapConfig.values);
        break;
      case PasswordBackend.none:
        // Do nothing
        break;
    }
    return config.toMap(_remote);
  }

  Future<ConfigCheckResult> checkConfig() async {
    if (!state.passwordlessLoginEnabled &&
        state.passwordBackend == PasswordBackend.none &&
        state.openIdConfigs.isEmpty) {
      return ConfigInvalid(error: 'You must enable at least 1 login method');
    }
    final config = validateConfig();
    if (config == null) {
      return ConfigInvalid(error: 'Unknown Error while validating config');
    }
    return ConfigCheckSuccess(config: config);
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
