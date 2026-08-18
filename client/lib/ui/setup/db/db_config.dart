import 'package:phylum/ui/settings/config/config.dart';

class DbConfigFields extends ConfigFields {
  static final fieldHost = PrimitiveField("localhost");
  static final fieldPort = PrimitiveField(5432);
  static final fieldDbName = PrimitiveField("phylum");
  static final fieldUser = PrimitiveField("phylum");
  static final fieldPassword = PrimitiveField("");

  static DbConfigFields instance = DbConfigFields._();

  DbConfigFields._();

  @override
  final ObjectField root = ObjectField(
    fields: {
      "host": fieldHost,
      "port": fieldPort,
      "name": fieldDbName,
      "user": fieldUser,
      "password": fieldPassword,
    },
  );
}
