class ServerConfig {
  final String publinkPath;
  final bool allowInvites;
  final bool passwordUpdate;
  final bool mail;

  ServerConfig({
    required this.publinkPath,
    required this.allowInvites,
    required this.passwordUpdate,
    required this.mail,
  });

  factory ServerConfig.fromMap(Map<String, dynamic> data) {
    return ServerConfig(
      publinkPath: data['publink_path'] ?? '/pub',
      allowInvites: data['allow_invites'] ?? true,
      passwordUpdate: data['password_update'] ?? true,
      mail: data['mail'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'publink_path': publinkPath,
      'allow_invites': allowInvites,
      'password_update': passwordUpdate,
      'mail': mail,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ServerConfig &&
        publinkPath == other.publinkPath &&
        allowInvites == other.allowInvites &&
        passwordUpdate == other.passwordUpdate &&
        mail == other.mail;
  }

  @override
  int get hashCode =>
      publinkPath.hashCode ^
      allowInvites.hashCode ^
      passwordUpdate.hashCode ^
      mail.hashCode;
}
