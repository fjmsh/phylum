import 'package:bloc/bloc.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config_cubit.dart';
import 'package:phylum/ui/config/auth/ldap/ldap_config_cubit.dart';
import 'package:phylum/ui/config/config.dart';

import 'password_config.dart';

class PasswordConfigState {
  final Set<PrimitiveField> _fixed;
  final bool enabled;
  final PasswordBackend passwordBackend;
  final bool mailEnabled;
  final bool resetEnabled;

  PasswordConfigState({
    required this._fixed,
    required this.enabled,
    required this.passwordBackend,
    required this.mailEnabled,
    required this.resetEnabled,
  });

  factory PasswordConfigState.createFromRemoteConfig(
    RemoteConfig<PasswordConfigFields> remote,
    bool mailEnabled,
  ) {
    final backend = remote.getValueOrDefault(PasswordConfigFields.fieldBackend);
    return PasswordConfigState(
      fixed: remote.fixed,
      enabled: backend != PasswordBackend.none,
      passwordBackend: backend == .none ? .crypt : backend,
      mailEnabled: mailEnabled,
      resetEnabled: remote.getValueOrDefault(
        PasswordConfigFields.fieldResetEnabled,
      ),
    );
  }

  PasswordConfigState copyWith({
    bool? enabled,
    PasswordBackend? passwordBackend,
    bool? mailEnabled,
    bool? resetEnabled,
  }) => PasswordConfigState(
    fixed: _fixed,
    enabled: enabled ?? this.enabled,
    passwordBackend: passwordBackend ?? this.passwordBackend,
    mailEnabled: mailEnabled ?? this.mailEnabled,
    resetEnabled: resetEnabled ?? this.resetEnabled,
  );

  bool isPasswordBackendFixed() =>
      _fixed.contains(PasswordConfigFields.fieldBackend);
  bool isResetEnabledFixed() =>
      _fixed.contains(PasswordConfigFields.fieldResetEnabled);

  @override
  bool operator ==(covariant PasswordConfigState other) {
    if (identical(this, other)) return true;
    return enabled == other.enabled &&
        passwordBackend == other.passwordBackend &&
        mailEnabled == other.mailEnabled &&
        resetEnabled == other.resetEnabled;
  }

  @override
  int get hashCode =>
      enabled.hashCode ^
      passwordBackend.hashCode ^
      mailEnabled.hashCode ^
      resetEnabled.hashCode;
}

class PasswordConfigCubit extends Cubit<PasswordConfigState> {
  final RemoteConfig<PasswordConfigFields> _remote;
  late final CryptConfigCubit cryptBloc;
  late final ldapBloc = LdapConfigCubit(
    remote: _remote.getObject(PasswordConfigFields.fieldLdap),
  );

  PasswordConfigCubit({
    required this._remote,
    required CryptConfigCubit Function(RemoteConfig<CryptConfigFields>)
    createCryptConfigCubit,
  }) : super(PasswordConfigState.createFromRemoteConfig(_remote, false)) {
    cryptBloc = createCryptConfigCubit(
      _remote.getObject(PasswordConfigFields.fieldCrypt),
    );
  }

  void reset() {
    emit(
      PasswordConfigState.createFromRemoteConfig(_remote, state.mailEnabled),
    );
    cryptBloc.reset();
    ldapBloc.reset();
  }

  set enabled(bool val) {
    emit(state.copyWith(enabled: val));
  }

  set passwordBackend(PasswordBackend val) {
    emit(state.copyWith(passwordBackend: val));
  }

  set mailEnabled(bool val) {
    emit(state.copyWith(mailEnabled: val));
  }

  set resetEnabled(bool val) {
    emit(state.copyWith(resetEnabled: val));
  }

  LocalConfig<PasswordConfigFields>? validate() {
    final config = LocalConfig<PasswordConfigFields>();
    final backend = state.enabled
        ? state.passwordBackend
        : PasswordBackend.none;
    config.setValue(PasswordConfigFields.fieldBackend, backend);
    config.setValue<bool>(
      PasswordConfigFields.fieldResetEnabled,
      state.resetEnabled && state.mailEnabled,
    );

    switch (backend) {
      case PasswordBackend.crypt:
        final cryptConfig = cryptBloc.validate();
        if (cryptConfig == null) {
          return null;
        }
        config.objects[PasswordConfigFields.fieldCrypt] = cryptConfig;
        break;
      case PasswordBackend.ldap:
        final ldapConfig = ldapBloc.validate();
        if (ldapConfig == null) {
          return null;
        }
        config.objects[PasswordConfigFields.fieldLdap] = ldapConfig;
        break;
      case PasswordBackend.none:
        // Do nothing
        break;
    }

    return config;
  }
}
