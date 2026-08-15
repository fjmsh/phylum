import 'package:phylum/ui/settings/config/config.dart';

class AuthConfigFields extends ConfigFields {
  static final fieldMagicLinks = PrimitiveField(false);
  static final fieldPasswordBackend = PrimitiveField(
    PasswordBackend.crypt,
    toPrimitive: (val) => val.name,
    fromPrimitive: (val) => PasswordBackend.fromString(val),
  );
  static final fieldPasswordResetEnabled = PrimitiveField(false);
  static final fieldPasswordCryptKdf = PrimitiveField(
    CryptKDF.argon2,
    toPrimitive: (val) => val.name,
    fromPrimitive: (val) => CryptKDF.fromString(val),
  );
  static final fieldPasswordCryptArgon2Memory = PrimitiveField(16);
  static final fieldPasswordCryptArgon2Iterations = PrimitiveField(4);
  static final fieldPasswordCryptArgon2Parallelism = PrimitiveField(2);
  static final fieldPasswordCryptPbkdf2Hash = PrimitiveField(
    HashFunction.sha256,
    toPrimitive: (val) => val.name,
    fromPrimitive: (val) => HashFunction.fromString(val),
  );
  static final fieldPasswordCryptPbkdf2Iterations = PrimitiveField(600_000);
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
  static final fieldOpenidClients = MapField(schema: OidcConfigFields.instance);

  static AuthConfigFields instance = AuthConfigFields._();

  AuthConfigFields._();

  @override
  final ObjectField root = ObjectField(
    fields: {
      "magic_links": fieldMagicLinks,
      "password": ObjectField(
        fields: {
          "backend": fieldPasswordBackend,
          "reset_enabled": fieldPasswordResetEnabled,
          "crypt": ObjectField(
            fields: {
              "kdf": fieldPasswordCryptKdf,
              "argon2": ObjectField(
                fields: {
                  "memory": fieldPasswordCryptArgon2Memory,
                  "iterations": fieldPasswordCryptArgon2Iterations,
                  "parallelism": fieldPasswordCryptArgon2Parallelism,
                },
              ),
              "pbkdf2": ObjectField(
                fields: {
                  "function": fieldPasswordCryptPbkdf2Hash,
                  "iterations": fieldPasswordCryptPbkdf2Iterations,
                },
              ),
            },
          ),
          "ldap": ObjectField(
            fields: {
              "debug": fieldPasswordLdapDebug,
              "url": fieldPasswordLdapUrl,
              "starttls": fieldPasswordLdapStarttls,
              "use_filter": fieldPasswordLdapUseFilter,
              "dn_template": fieldPasswordLdapUrl,
              "filter": ObjectField(
                fields: {
                  "bind_dn": fieldPasswordLdapFilterBindDn,
                  "bind_password": fieldPasswordLdapFilterBindPassword,
                  "base_dn": fieldPasswordLdapFilterBaseDn,
                  "template": fieldPasswordLdapDnTemplate,
                },
              ),
              "auto_create_users": fieldPasswordLdapAutoCreateUsers,
            },
          ),
          "requirements": ObjectField(
            fields: {
              "length": fieldPasswordRequirementsLength,
              "upper": fieldPasswordRequirementsUpper,
              "lower": fieldPasswordRequirementsLower,
              "numeric": fieldPasswordRequirementsNumeric,
              "symbols": fieldPasswordRequirementsSymbols,
            },
          ),
        },
      ),
      "openid": ObjectField(fields: {"clients": fieldOpenidClients}),
    },
  );
}

class OidcConfigFields extends ConfigFields {
  static final fieldName = PrimitiveField("");
  static final fieldIssuerUrl = PrimitiveField("");
  static final fieldClientId = PrimitiveField("");
  static final fieldClientSecret = PrimitiveField("");
  static final fieldAllowUnverifiedEmails = PrimitiveField(false);
  static final fieldAutoCreateUsers = PrimitiveField(false);

  static OidcConfigFields instance = OidcConfigFields._();

  OidcConfigFields._();

  @override
  ObjectField get root => ObjectField(
    fields: {
      "name": fieldName,
      "issuer_url": fieldIssuerUrl,
      "client_id": fieldClientId,
      "client_secret": fieldClientSecret,
      "allow_unverified_emails": fieldAllowUnverifiedEmails,
      "auto_create_users": fieldAutoCreateUsers,
    },
  );
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

enum CryptKDF {
  argon2('argon2', 'Argon2'),
  pbkdf2('pbkdf2', 'PBKDF2');

  final String name;
  final String descriptor;

  const CryptKDF(this.name, this.descriptor);

  static CryptKDF fromString(String s) {
    return switch (s) {
      'argon2' => .argon2,
      'pbkdf2' => .pbkdf2,
      _ => .argon2,
    };
  }
}

enum HashFunction {
  sha1('sha-1', 'SHA-1'),
  sha256('sha-256', 'SHA-256'),
  sha512('sha-512', 'SHA-512');

  final String name;
  final String descriptor;

  const HashFunction(this.name, this.descriptor);

  static HashFunction fromString(String s) {
    for (final h in HashFunction.values) {
      if (h.name == s) {
        return h;
      }
    }
    return .sha256;
  }
}
