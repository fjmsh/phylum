import 'package:phylum/ui/config/config.dart';

class LdapConfigFields extends ConfigFields {
  static final fieldDebug = PrimitiveField(false);
  static final fieldUrl = PrimitiveField("");
  static final fieldStarttls = PrimitiveField(false);
  static final fieldUseFilter = PrimitiveField(false);
  static final fieldDnTemplate = PrimitiveField(
    "uid={email},ou=people,dc=example,dc=com",
  );
  static final fieldFilterBindDn = PrimitiveField('');
  static final fieldFilterBindPassword = PrimitiveField('');
  static final fieldFilterBaseDn = PrimitiveField('dc=example,dc=com');
  static final fieldFilterTemplate = PrimitiveField('(mail={email})');
  static final fieldAutoCreateUsers = PrimitiveField(false);

  static LdapConfigFields instance = LdapConfigFields._();

  LdapConfigFields._();

  @override
  AnonymousObjectField get root => AnonymousObjectField({
    "debug": fieldDebug,
    "url": fieldUrl,
    "starttls": fieldStarttls,
    "use_filter": fieldUseFilter,
    "dn_template": fieldUrl,
    "filter": AnonymousObjectField({
      "bind_dn": fieldFilterBindDn,
      "bind_password": fieldFilterBindPassword,
      "base_dn": fieldFilterBaseDn,
      "template": fieldDnTemplate,
    }),
    "auto_create_users": fieldAutoCreateUsers,
  });
}
