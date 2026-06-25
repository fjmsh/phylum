class ServerConfig {
  final bool allowInvites;
  final bool mail;
  final bool passwordUpdate;
  final String publinkPath;
  final String version;

  ServerConfig({
    required this.allowInvites,
    required this.mail,
    required this.passwordUpdate,
    required this.publinkPath,
    required this.version,
  });

  factory ServerConfig.fromMap(Map<String, dynamic> data) {
    return ServerConfig(
      allowInvites: data['allow_invites'] ?? true,
      mail: data['mail'] ?? true,
      passwordUpdate: data['password_update'] ?? true,
      publinkPath: data['publink_path'] ?? '/pub',
      version: data['version'] ?? '0.0.0',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allow_invites': allowInvites,
      'mail': mail,
      'password_update': passwordUpdate,
      'publink_path': publinkPath,
      'version': version,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ServerConfig &&
        allowInvites == other.allowInvites &&
        mail == other.mail &&
        passwordUpdate == other.passwordUpdate &&
        publinkPath == other.publinkPath &&
        version == other.version;
  }

  @override
  int get hashCode =>
      allowInvites.hashCode ^
      mail.hashCode ^
      passwordUpdate.hashCode ^
      publinkPath.hashCode ^
      version.hashCode;
}
