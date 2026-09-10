import 'package:phylum/ui/config/auth/openid/openid_config_fields.dart';
import 'package:phylum/ui/config/auth/password/password_config.dart';
import 'package:phylum/ui/config/config.dart';

class AuthConfigFields extends ConfigFields {
  static final fieldMagicLinks = PrimitiveField(false);
  static final fieldPassword = ObjectField(
    schema: PasswordConfigFields.instance,
  );
  static final fieldOpenidClients = MapField(
    schema: OpenidConfigFields.instance,
  );

  static AuthConfigFields instance = AuthConfigFields._();

  AuthConfigFields._();

  @override
  final AnonymousObjectField root = AnonymousObjectField({
    "magic_links": fieldMagicLinks,
    "password": fieldPassword,
    "openid": AnonymousObjectField({"clients": fieldOpenidClients}),
  });
}
