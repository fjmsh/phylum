class MailConfig {
  final SmtpConfig smtp;

  MailConfig({required this.smtp});

  factory MailConfig.fromMap(Map<String, dynamic> data) {
    return MailConfig(enabled: data['smtp']);
  }

  @override
  bool operator ==(Object other) {
    return other is MailConfig && other.enabled == enabled;
  }

  @override
  int get hashCode => enabled.hashCode;
}

class SmtpConfig {
  final String host;
  final int port;
  final String username;

  SmtpConfig({required this.host, required this.port, required this.username});

  @override
  bool operator ==(Object other) {
    return other is SmtpConfig &&
        host == other.host &&
        port == other.port &&
        username == other.username;
  }

  @override
  int get hashCode => host.hashCode ^ port.hashCode ^ username.hashCode;
}
