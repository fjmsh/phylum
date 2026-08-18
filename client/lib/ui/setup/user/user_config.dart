import 'package:phylum/ui/settings/config/config.dart';

class UserConfigFields extends ConfigFields {
  static final fieldEmail = PrimitiveField("");
  static final fieldName = PrimitiveField("");
  static final fieldPassword = PrimitiveField("");

  static UserConfigFields instance = UserConfigFields._();

  UserConfigFields._();

  @override
  final ObjectField root = ObjectField(
    fields: {"email": fieldEmail, "name": fieldName, "password": fieldPassword},
  );
}
