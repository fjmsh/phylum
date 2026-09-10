import 'package:bloc/bloc.dart';
import 'package:phylum/ui/config/auth/crypt/crypt_config_cubit.dart';
import 'package:phylum/ui/config/auth/ldap/ldap_config_cubit.dart';
import 'package:phylum/ui/config/config.dart';

import 'password_config.dart';

class PasswordConfigState {
  final Set<PrimitiveField> _fixed;
  final PasswordBackend passwordBackend;
  final bool mailEnabled;
  final bool resetEnabled;

  PasswordConfigState({
    required this._fixed,
    required this.passwordBackend,
    required this.mailEnabled,
    required this.resetEnabled,
  });

  factory PasswordConfigState.createFromRemoteConfig(
    RemoteConfig<PasswordConfigFields> remote,
    bool mailEnabled,
  ) {
    return PasswordConfigState(
      fixed: remote.fixed,
      passwordBackend: remote.getValueOrDefault(
        PasswordConfigFields.fieldBackend,
      ),
      mailEnabled: mailEnabled,
      resetEnabled: remote.getValueOrDefault(
        PasswordConfigFields.fieldResetEnabled,
      ),
    );
  }

  PasswordConfigState copyWith({
    PasswordBackend? passwordBackend,
    bool? mailEnabled,
    bool? resetEnabled,
  }) => PasswordConfigState(
    fixed: _fixed,
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
    return passwordBackend == other.passwordBackend &&
        mailEnabled == other.mailEnabled &&
        resetEnabled == other.resetEnabled;
  }

  @override
  int get hashCode =>
      passwordBackend.hashCode ^ mailEnabled.hashCode ^ resetEnabled.hashCode;
}

class PasswordConfigCubit extends Cubit<PasswordConfigState> {
  final RemoteConfig<PasswordConfigFields> _remote;
  late final cryptBloc = CryptConfigCubit(
    remote: _remote.getObject(PasswordConfigFields.fieldCrypt),
  );
  late final LdapConfigCubit ldapBloc = LdapConfigCubit(
    remote: _remote.getObject(PasswordConfigFields.fieldLdap),
  );

  PasswordConfigCubit({required this._remote})
    : super(PasswordConfigState.createFromRemoteConfig(_remote, false));

  void reset() {
    emit(
      PasswordConfigState.createFromRemoteConfig(_remote, state.mailEnabled),
    );
    cryptBloc.reset();
    ldapBloc.reset();
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
    config.setValue(PasswordConfigFields.fieldBackend, state.passwordBackend);
    config.setValue<bool>(
      PasswordConfigFields.fieldResetEnabled,
      state.resetEnabled && state.mailEnabled,
    );

    switch (state.passwordBackend) {
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
