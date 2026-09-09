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
  static final fieldPasswordResetEnabled = PrimitiveField(false);
  static final fieldPasswordRequirementsLength = PrimitiveField(8);
  static final fieldPasswordRequirementsUpper = PrimitiveField(0);
  static final fieldPasswordRequirementsLower = PrimitiveField(0);
  static final fieldPasswordRequirementsNumeric = PrimitiveField(0);
  static final fieldPasswordRequirementsSymbols = PrimitiveField(0);
  static final fieldPasswordLdapDebug = PrimitiveField(false);
  static final fieldPasswordLdapUrl = PrimitiveField("");
  static final fieldPasswordLdapStarttls = PrimitiveField(false);
  static final fieldPasswordLdapUseFilter = PrimitiveField(false);
  static final fieldPasswordLdapDnTemplate = PrimitiveField(
    "uid={email},ou=people,dc=example,dc=com",
  );
  static final fieldPasswordLdapFilterBindDn = PrimitiveField('');
  static final fieldPasswordLdapFilterBindPassword = PrimitiveField('');
  static final fieldPasswordLdapFilterBaseDn = PrimitiveField(
    'dc=example,dc=com',
  );
  static final fieldPasswordLdapFilterTemplate = PrimitiveField(
    '(mail={email})',
  );
  static final fieldPasswordLdapAutoCreateUsers = PrimitiveField(false);
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
      "ldap": AnonymousObjectField({
        "debug": fieldPasswordLdapDebug,
        "url": fieldPasswordLdapUrl,
        "starttls": fieldPasswordLdapStarttls,
        "use_filter": fieldPasswordLdapUseFilter,
        "dn_template": fieldPasswordLdapUrl,
        "filter": AnonymousObjectField({
          "bind_dn": fieldPasswordLdapFilterBindDn,
          "bind_password": fieldPasswordLdapFilterBindPassword,
          "base_dn": fieldPasswordLdapFilterBaseDn,
          "template": fieldPasswordLdapDnTemplate,
        }),
        "auto_create_users": fieldPasswordLdapAutoCreateUsers,
      }),
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
