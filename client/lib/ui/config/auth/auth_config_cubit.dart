import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:phylum/ui/config/auth/auth_config.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config_cubit.dart';
import 'package:phylum/ui/config/auth/openid/openid_config_cubit.dart';
import 'package:phylum/ui/config/auth/password/password_config_cubit.dart';
import 'package:phylum/ui/config/config.dart';
import 'package:phylum/ui/config/config_check_result.dart';

class AuthConfigState {
  final bool mailEnabled;
  final bool passwordlessLoginEnabled;
  final Map<String, OpenIDConfig> openIdConfigs;

  AuthConfigState({
    required this.mailEnabled,
    required this.passwordlessLoginEnabled,
    required this.openIdConfigs,
  });

  factory AuthConfigState.createFromRemoteConfig({
    required bool mailEnabled,
    required RemoteConfig<AuthConfigFields> config,
  }) {
    final openIdConfigs = config
        .getMap(AuthConfigFields.fieldOpenidClients)
        .map((id, config) {
          return MapEntry(id, OpenIDConfig.createFromConfig(config));
        });
    return AuthConfigState(
      mailEnabled: mailEnabled,
      passwordlessLoginEnabled: config.getValueOrDefault(
        AuthConfigFields.fieldMagicLinks,
      ),
      openIdConfigs: openIdConfigs,
    );
  }

  AuthConfigState copyWith({
    bool? mailEnabled,
    bool? passwordlessLoginEnabled,
    Map<String, OpenIDConfig>? openIdConfigs,
  }) => AuthConfigState(
    mailEnabled: mailEnabled ?? this.mailEnabled,
    passwordlessLoginEnabled:
        passwordlessLoginEnabled ?? this.passwordlessLoginEnabled,
    openIdConfigs: openIdConfigs ?? this.openIdConfigs,
  );

  @override
  String toString() =>
      'AuthConfigFormState('
      'mailEnabled: $mailEnabled, '
      'passwordlessLoginEnabled: $passwordlessLoginEnabled'
      'openIdConfigs: $openIdConfigs,'
      ')';

  @override
  bool operator ==(covariant AuthConfigState other) {
    if (identical(this, other)) return true;

    return other.mailEnabled == mailEnabled &&
        other.passwordlessLoginEnabled == passwordlessLoginEnabled &&
        const MapEquality().equals(other.openIdConfigs, openIdConfigs);
  }

  @override
  int get hashCode =>
      mailEnabled.hashCode ^
      passwordlessLoginEnabled.hashCode ^
      const MapEquality().hash(openIdConfigs);
}

class AuthConfigCubit extends Cubit<AuthConfigState> {
  final RemoteConfig<AuthConfigFields> _remote;
  late final PasswordConfigCubit passwordBloc;

  AuthConfigCubit({
    required this._remote,
    required CryptConfigCubit Function(RemoteConfig<CryptConfigFields>)
    createCryptConfigCubit,
  }) : super(
         AuthConfigState.createFromRemoteConfig(
           config: _remote,
           mailEnabled: false,
         ),
       ) {
    passwordBloc = PasswordConfigCubit(
      remote: _remote.getObject(AuthConfigFields.fieldPassword),
      createCryptConfigCubit: createCryptConfigCubit,
    );
  }

  void reset() {
    emit(
      AuthConfigState.createFromRemoteConfig(
        config: _remote,
        mailEnabled: state.mailEnabled,
      ),
    );
    passwordBloc.reset();
  }

  set mailEnabled(bool val) {
    emit(state.copyWith(mailEnabled: val));
    passwordBloc.mailEnabled = val;
  }

  set passwordlessLoginEnabled(bool val) {
    emit(state.copyWith(passwordlessLoginEnabled: val));
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
    final config = LocalConfig<AuthConfigFields>();
    config.setValue(
      AuthConfigFields.fieldMagicLinks,
      state.passwordlessLoginEnabled,
    );
    final passwordConfig = passwordBloc.validate();
    if (passwordConfig != null) {
      config.objects[AuthConfigFields.fieldPassword] = passwordConfig;
    }
    state.openIdConfigs.forEach((key, openidConfig) {
      config.addMapEntry(
        AuthConfigFields.fieldOpenidClients,
        key,
        openidConfig.toLocalConfig(),
      );
    });
    return config.toMap(_remote);
  }

  Future<ConfigCheckResult> checkConfig() async {
    if (!state.passwordlessLoginEnabled &&
        !passwordBloc.state.enabled &&
        state.openIdConfigs.isEmpty) {
      return ConfigInvalid(error: 'You must enable at least 1 login method');
    }
    final config = validateConfig();
    if (config == null) {
      return ConfigInvalid();
    }
    return ConfigCheckSuccess(config: config);
  }
}
