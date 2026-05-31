import 'package:collection/collection.dart';
import 'package:state_notifier/state_notifier.dart';

import 'crypt.dart';
import 'crypt_argon2.dart';
import 'crypt_pbkdf2.dart';
import 'ldap.dart';
import 'openid.dart';
import 'password.dart';

class AuthController extends StateNotifier<AuthConfig> {
  AuthController() : super(AuthConfig.defaults());

  set passwordlessLoginEnabled(bool enabled) {
    state = state.copyWith(passwordlessLoginEnabled: enabled);
  }

  set passwordLoginEnabled(bool enabled) {
    state = state.copyWith(passwordLoginEnabled: enabled);
  }

  set passwordConfig(PasswordConfig config) {
    state = state.copyWith(passwordConfig: config);
  }

  void addOpenIDConfig(OpenIDConfig config) {
    state = state.copyWith(
        openIdConfigs:
            [...state.openIdConfigs, config].toList(growable: false));
  }

  void removeOpenIDConfig(OpenIDConfig config) {
    state = state.copyWith(
        openIdConfigs: state.openIdConfigs
            .whereNot((e) => e == config)
            .toList(growable: false));
  }
}

class AuthConfig {
  final bool passwordlessLoginEnabled;
  final bool passwordLoginEnabled;
  final PasswordConfig passwordConfig;
  final List<OpenIDConfig> openIdConfigs;

  const AuthConfig({
    required this.passwordlessLoginEnabled,
    required this.passwordLoginEnabled,
    required this.passwordConfig,
    required this.openIdConfigs,
  });

  const AuthConfig.defaults()
      : this(
          passwordlessLoginEnabled: false,
          passwordLoginEnabled: false,
          passwordConfig: const PasswordConfig(
            backend: PasswordBackend.crypt,
            cryptConfig: CryptConfig(
              kdf: CryptKDF.argon2,
              argon2Config: Argon2Config.defaults(),
              pbkdf2Config: Pbkdf2Config.defaults(),
            ),
            ldapConfig: LdapConfig.defaults(),
            resetEnabled: true,
          ),
          openIdConfigs: const [],
        );

  bool get valid =>
      passwordLoginEnabled ||
      passwordlessLoginEnabled ||
      openIdConfigs.isNotEmpty;

  AuthConfig copyWith({
    PasswordConfig? passwordConfig,
    bool? passwordLoginEnabled,
    bool? passwordlessLoginEnabled,
    List<OpenIDConfig>? openIdConfigs,
  }) {
    return AuthConfig(
      passwordlessLoginEnabled:
          passwordlessLoginEnabled ?? this.passwordlessLoginEnabled,
      passwordLoginEnabled: passwordLoginEnabled ?? this.passwordLoginEnabled,
      passwordConfig: passwordConfig ?? this.passwordConfig,
      openIdConfigs: openIdConfigs ?? this.openIdConfigs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'password': {
        if (passwordLoginEnabled)
          ...passwordConfig.toMap()
        else
          'backend': 'none',
      },
      'magic_links': passwordlessLoginEnabled,
      'openid': const {},
    };
  }
}
