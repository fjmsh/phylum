import 'package:phylum/ui/config/auth/crypt/crypt_config.dart';
import 'package:phylum/ui/config/auth/ldap/ldap_config.dart';
import 'package:phylum/ui/config/config.dart';

class PasswordConfigFields extends ConfigFields {
  static final fieldBackend = PrimitiveField(
    PasswordBackend.crypt,
    toPrimitive: (val) => val.name,
    fromPrimitive: (val) => PasswordBackend.fromString(val),
  );

  static final fieldCrypt = ObjectField(schema: CryptConfigFields.instance);
  static final fieldLdap = ObjectField(schema: LdapConfigFields.instance);
  static final fieldResetEnabled = PrimitiveField(false);
  static final fieldRequirementsLength = PrimitiveField(8);
  static final fieldRequirementsUpper = PrimitiveField(0);
  static final fieldRequirementsLower = PrimitiveField(0);
  static final fieldRequirementsNumeric = PrimitiveField(0);
  static final fieldRequirementsSymbols = PrimitiveField(0);

  static PasswordConfigFields instance = PasswordConfigFields._();

  PasswordConfigFields._();

  @override
  AnonymousObjectField get root => AnonymousObjectField({
    "backend": fieldBackend,
    "reset_enabled": fieldResetEnabled,
    "crypt": fieldCrypt,
    "ldap": fieldLdap,
    "requirements": AnonymousObjectField({
      "length": fieldRequirementsLength,
      "upper": fieldRequirementsUpper,
      "lower": fieldRequirementsLower,
      "numeric": fieldRequirementsNumeric,
      "symbols": fieldRequirementsSymbols,
    }),
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
