import 'package:phylum/ui/settings/config/remote_config_controller.dart';

class MailConfig implements Config {
  final bool enabled;
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final String fromName;
  final String fromEmail;
  final String instanceUrl;

  const MailConfig({
    required this.enabled,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.fromName,
    required this.fromEmail,
    required this.instanceUrl,
  });

  MailConfig.defaults(String? defaultInstanceUrl)
    : this(
        enabled: false,
        smtpHost: '',
        smtpPort: 587,
        smtpUsername: '',
        smtpPassword: '',
        fromEmail: '',
        fromName: '',
        instanceUrl: defaultInstanceUrl ?? '',
      );

  MailConfig copyWith({
    bool? enabled,
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    String? fromName,
    String? fromEmail,
    String? instanceUrl,
  }) {
    return MailConfig(
      enabled: enabled ?? this.enabled,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      fromName: fromName ?? this.fromName,
      fromEmail: fromEmail ?? this.fromEmail,
      instanceUrl: instanceUrl ?? this.instanceUrl,
    );
  }

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
