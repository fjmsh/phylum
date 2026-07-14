import 'dart:convert';

import 'package:phylum/libphylum/phylum_account.dart';
import 'package:state_notifier/state_notifier.dart';

const _persistKeyConfig = 'config';

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

  ServerConfig copyWith({bool? mail}) => ServerConfig(
    allowInvites: allowInvites,
    mail: mail ?? this.mail,
    passwordUpdate: passwordUpdate,
    publinkPath: publinkPath,
    version: version,
  );

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

class ServerConfigNotifier extends StateNotifier<ServerConfig> {
  final PhylumAccount _account;

  ServerConfig get config => state;
  set config(ServerConfig value) => state = value;

  ServerConfigNotifier._(this._account, super.state) {
    stream.listen((config) {
      _account.persist(_persistKeyConfig, jsonEncode(config.toMap()));
    });
  }

  factory ServerConfigNotifier.fromConfig(
    PhylumAccount account,
    ServerConfig config,
  ) {
    account.persist(_persistKeyConfig, jsonEncode(config.toMap()));
    return ServerConfigNotifier._(account, config);
  }

  factory ServerConfigNotifier.fromAccount(PhylumAccount account) {
    final config = ServerConfig.fromMap(
      jsonDecode(account.getPersisted(_persistKeyConfig)),
    );
    return ServerConfigNotifier._(account, config);
  }

  @override
  bool updateShouldNotify(ServerConfig old, ServerConfig current) {
    return old != current;
  }
}
