import 'package:phylum/ui/settings/config/local_config_updates.dart';
import 'package:phylum/ui/settings/config/remote_config.dart';

class MailConfig extends LocalConfigUpdates<MailConfigFields> {
  final bool enabled;
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final String fromName;
  final String fromEmail;
  final String instanceUrl;

  MailConfig({
    required this.enabled,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.fromName,
    required this.fromEmail,
    required this.instanceUrl,
  });

  factory MailConfig.fromMap(Map<String, dynamic> map) {
    return MailConfig(
      enabled: map['enabled'],
      smtpHost: map['smtp']['host'],
      smtpPort: map['smtp']['port'],
      smtpUsername: map['smtp']['username'],
      smtpPassword: map['smtp']['password'],
      fromName: map['from']['name'],
      fromEmail: map['from']['email'],
      instanceUrl: map['instance'],
    );
  }

  @override
  Map<String, dynamic> toMap() => enabled
      ? {
          'enabled': enabled,
          'smtp': {
            'host': smtpHost,
            'port': smtpPort,
            'username': smtpUsername,
            if (smtpPassword.isNotEmpty) 'password': smtpPassword,
          },
          'from': {'name': fromName, 'email': fromEmail},
          'instance': instanceUrl,
        }
      : const {'enabled': false};

  @override
  bool operator ==(covariant MailConfig other) {
    if (identical(this, other)) return true;

    return other.enabled == enabled &&
        other.smtpHost == smtpHost &&
        other.smtpPort == smtpPort &&
        other.smtpUsername == smtpUsername &&
        other.smtpPassword == smtpPassword &&
        other.fromEmail == fromEmail &&
        other.fromName == fromName &&
        other.instanceUrl == instanceUrl;
  }

  @override
  int get hashCode =>
      enabled.hashCode ^
      smtpHost.hashCode ^
      smtpPort.hashCode ^
      smtpUsername.hashCode ^
      smtpPassword.hashCode ^
      fromEmail.hashCode ^
      fromName.hashCode ^
      instanceUrl.hashCode;
}

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
      "enabled": PrimitiveField(false),
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
