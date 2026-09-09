import 'package:phylum/ui/config/config.dart';

class MailConfigFields extends ConfigFields {
  static final fieldEnabled = PrimitiveField(false);
  static final fieldSmtpHost = PrimitiveField("");
  static final fieldSmtpPort = PrimitiveField(587);
  static final fieldSmtpUsername = PrimitiveField("");
  static final fieldSmtpPassword = PrimitiveField("");
  static final fieldFromName = PrimitiveField("Phylum Drive");
  static final fieldFromEmail = PrimitiveField("");
  static final fieldInstance = PrimitiveField("");

  static MailConfigFields instance = MailConfigFields._();

  MailConfigFields._();

  @override
  final ObjectField root = ObjectField(
    fields: {
      "enabled": fieldEnabled,
      "smtp": ObjectField(
        fields: {
          "host": fieldSmtpHost,
          "port": fieldSmtpPort,
          "username": fieldSmtpUsername,
          "password": fieldSmtpPassword,
        },
      ),
      "from": ObjectField(
        fields: {"name": fieldFromName, "email": fieldFromEmail},
      ),
      "instance": fieldInstance,
    },
  );
}
