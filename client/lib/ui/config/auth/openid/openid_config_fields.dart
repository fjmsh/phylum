import 'package:phylum/ui/config/config.dart';

class OpenidConfigFields extends ConfigFields {
  static final fieldName = PrimitiveField("");
  static final fieldIssuerUrl = PrimitiveField("");
  static final fieldClientId = PrimitiveField("");
  static final fieldClientSecret = PrimitiveField("");
  static final fieldAllowUnverifiedEmails = PrimitiveField(false);
  static final fieldAutoCreateUsers = PrimitiveField(false);

  static OpenidConfigFields instance = OpenidConfigFields._();

  OpenidConfigFields._();

  @override
  AnonymousObjectField get root => AnonymousObjectField({
    "name": fieldName,
    "issuer_url": fieldIssuerUrl,
    "client_id": fieldClientId,
    "client_secret": fieldClientSecret,
    "allow_unverified_emails": fieldAllowUnverifiedEmails,
    "auto_create_users": fieldAutoCreateUsers,
  });
}
