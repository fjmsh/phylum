import 'package:phylum/ui/config/auth/ldap/ldap_config.dart';
import 'package:phylum/ui/config/auth/openid/openid_config_fields.dart';
import 'package:phylum/ui/config/config.dart';

import 'crypt/crypt_config.dart';

class AuthConfigFields extends ConfigFields {
  static final fieldMagicLinks = PrimitiveField(false);
  static final fieldPasswordBackend = PrimitiveField(
    PasswordBackend.crypt,
    toPrimitive: (val) => val.name,
    fromPrimitive: (val) => PasswordBackend.fromString(val),
  );

  static final fieldPasswordCrypt = ObjectField(
    schema: CryptConfigFields.instance,
  );
  static final fieldPasswordLdap = ObjectField(
    schema: LdapConfigFields.instance,
  );
  static final fieldPasswordResetEnabled = PrimitiveField(false);
  static final fieldPasswordRequirementsLength = PrimitiveField(8);
  static final fieldPasswordRequirementsUpper = PrimitiveField(0);
  static final fieldPasswordRequirementsLower = PrimitiveField(0);
  static final fieldPasswordRequirementsNumeric = PrimitiveField(0);
  static final fieldPasswordRequirementsSymbols = PrimitiveField(0);
  static final fieldOpenidClients = MapField(
    schema: OpenidConfigFields.instance,
  );

  static AuthConfigFields instance = AuthConfigFields._();

  AuthConfigFields._();

  @override
  final AnonymousObjectField root = AnonymousObjectField({
    "magic_links": fieldMagicLinks,
    "password": AnonymousObjectField({
      "backend": fieldPasswordBackend,
      "reset_enabled": fieldPasswordResetEnabled,
      "crypt": fieldPasswordCrypt,
      "ldap": fieldPasswordLdap,
      "requirements": AnonymousObjectField({
        "length": fieldPasswordRequirementsLength,
        "upper": fieldPasswordRequirementsUpper,
        "lower": fieldPasswordRequirementsLower,
        "numeric": fieldPasswordRequirementsNumeric,
        "symbols": fieldPasswordRequirementsSymbols,
      }),
    }),
    "openid": AnonymousObjectField({"clients": fieldOpenidClients}),
  });
}

enum PasswordBackend {
  none('none', 'Disabled'),
  crypt('crypt', 'Crypt (Local DB)'),
  ldap('ldap', 'LDAP');

  final String name;
  final String descriptor;

  const PasswordBackend(this.name, this.descriptor);

  static PasswordBackend fromString(String s) {
    return switch (s) {
      'crypt' => .crypt,
      'ldap' => .ldap,
      _ => .none,
    };
  }
}
