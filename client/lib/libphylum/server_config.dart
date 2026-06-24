class ServerConfig {
  final String publinkPath;
  final bool allowInvites;
  final PasswordConfig password;
  final MailConfig mail;

  ServerConfig({
    required this.publinkPath,
    required this.allowInvites,
    required this.password,
    required this.mail,
  });

  factory ServerConfig.fromMap(Map<String, dynamic> data) {
    return ServerConfig(
      publinkPath: data['publink_path'] ?? '/pub',
      allowInvites: data['allow_invites'] ?? true,
      password: PasswordConfig.fromMap((data['password'] as Map?)?.cast()),
      mail: MailConfig.fromMap((data['mail'] as Map?)?.cast()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'publink_path': publinkPath,
      'allow_invites': allowInvites,
      'password': password.toMap(),
      'mail': mail.toMap(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ServerConfig &&
        publinkPath == other.publinkPath &&
        allowInvites == other.allowInvites &&
        password == other.password &&
        mail == other.mail;
  }

  @override
  int get hashCode => publinkPath.hashCode ^ password.hashCode ^ mail.hashCode;
}

class PasswordConfig {
  final bool enabled;
  final bool supportsUpdate;

  PasswordConfig({required this.enabled, required this.supportsUpdate});

  factory PasswordConfig.fromMap(Map<String, dynamic>? data) {
    return PasswordConfig(
      enabled: data?['enabled'] ?? true,
      supportsUpdate: data?['supports_update'] ?? true,
    );
  }
  Map<String, dynamic> toMap() {
    return {'enabled': enabled, 'supports_update': supportsUpdate};
  }

  @override
  bool operator ==(Object other) {
    return other is PasswordConfig &&
        other.enabled == enabled &&
        other.supportsUpdate == supportsUpdate;
  }

  @override
  int get hashCode => enabled.hashCode ^ supportsUpdate.hashCode;
}

class MailConfig {
  final bool enabled;

  MailConfig({required this.enabled});

  factory MailConfig.fromMap(Map<String, dynamic>? data) {
    return MailConfig(enabled: data?['enabled'] ?? true);
  }
  Map<String, dynamic> toMap() {
    return {'enabled': enabled};
  }

  @override
  bool operator ==(Object other) {
    return other is MailConfig && other.enabled == enabled;
  }

  @override
  int get hashCode => enabled.hashCode;
}
