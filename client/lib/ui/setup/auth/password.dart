import 'package:phylum/ui/setup/auth/crypt.dart';
import 'package:phylum/ui/setup/auth/ldap.dart';

class PasswordConfig {
  final PasswordBackend backend;
  final CryptConfig cryptConfig;
  final LdapConfig ldapConfig;
  final bool resetEnabled;

  const PasswordConfig({
    required this.backend,
    required this.cryptConfig,
    required this.ldapConfig,
    required this.resetEnabled,
  });

  PasswordConfig copyWith({
    PasswordBackend? backend,
    CryptConfig? cryptConfig,
    LdapConfig? ldapConfig,
    bool? resetEnabled,
  }) {
    return PasswordConfig(
      backend: backend ?? this.backend,
      cryptConfig: cryptConfig ?? this.cryptConfig,
      ldapConfig: ldapConfig ?? this.ldapConfig,
      resetEnabled: resetEnabled ?? this.resetEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return switch (backend) {
      PasswordBackend.crypt => {
          'backend': 'crypt',
          'crypt': cryptConfig.toMap(),
          'reset_enabled': resetEnabled,
        },
      PasswordBackend.ldap => {
          'backend': 'ldap',
          'ldap': ldapConfig.toMap(),
          'reset_enabled': false,
        },
    };
  }
}

enum PasswordBackend {
  crypt('crypt', 'Crypt (Local DB)'),
  ldap('ldap', 'LDAP');

  final String name;
  final String descriptor;

  const PasswordBackend(this.name, this.descriptor);
}
