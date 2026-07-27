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
  static const fieldEnabled = FieldDef(path: "enabled", defaultValue: true);
  static const fieldSmtpHost = FieldDef(path: "smtp.host", defaultValue: "");
  static const fieldSmtpPort = FieldDef(path: "smtp.port", defaultValue: 587);
  static const fieldSmtpUsername = FieldDef(
    path: "smtp.username",
    defaultValue: "",
  );
  static const fieldSmtpPassword = FieldDef(
    path: "smtp.password",
    defaultValue: "",
  );
  static const fieldFromName = FieldDef(
    path: "from.name",
    defaultValue: "Phylum Drive",
  );
  static const fieldFromEmail = FieldDef(path: "from.email", defaultValue: "");
  static const fieldInstance = FieldDef(path: "instance", defaultValue: "");

  const MailConfigFields();

  @override
  List<FieldDef> get fields => const [
    fieldEnabled,
    fieldSmtpHost,
    fieldSmtpPort,
    fieldSmtpUsername,
    fieldSmtpPassword,
    fieldFromName,
    fieldFromEmail,
    fieldInstance,
  ];
}
