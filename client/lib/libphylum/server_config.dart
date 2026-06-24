class ServerConfig {
  final String publinkPath;
  final PasswordConfig passwordConfig;
  final MailConfig mailConfig;

  ServerConfig({
    required this.publinkPath,
    required this.passwordConfig,
    required this.mailConfig,
  });

  factory ServerConfig.fromMap(Map<String, dynamic> data) {
    return ServerConfig(
      publinkPath: data['publink_path'] ?? '/pub',
      passwordConfig: PasswordConfig.fromMap(
        (data['password'] as Map?)?.cast(),
      ),
      mailConfig: MailConfig.fromMap((data['mail'] as Map?)?.cast()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'publink_path': publinkPath,
      'password': passwordConfig.toMap(),
      'mail': mailConfig.toMap(),
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ServerConfig && publinkPath == other.publinkPath;
  }

  @override
  int get hashCode => publinkPath.hashCode;
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
}
