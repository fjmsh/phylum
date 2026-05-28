import 'dart:convert';

import 'package:state_notifier/state_notifier.dart';

import 'phylum_account.dart';
import 'user_permission.dart';

const _persistKeyUser = 'user';

class AccountUser {
  final int id;
  final String email;
  final String name;
  final String home;
  final List<String> permissions;

  AccountUser({
    required this.id,
    required this.email,
    required this.name,
    required this.home,
    required this.permissions,
  });

  bool hasPermission(UserPermission p) {
    final parts = p.split(':');

    outer:
    for (final up in permissions) {
      final upParts = up.split(':');
      if (upParts.length > parts.length) continue;
      for (int i = 0; i < upParts.length; i++) {
        if (upParts[i] != '*' && upParts[i] != parts[i]) continue outer;
      }
      return true;
    }
    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! AccountUser) return false;

    return id == other.id &&
        email == other.email &&
        name == other.name &&
        home == other.home &&
        permissions == other.permissions;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode ^ home.hashCode ^ permissions.hashCode;

  Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "name": name,
        "home": home,
        "permissions": permissions,
      };

  factory AccountUser.fromJson(Map<String, dynamic> map) {
    return AccountUser(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      home: map['home'],
      permissions: (map['permissions'] as List).cast<String>(),
    );
  }

  AccountUser copyWith({String? name}) {
    return AccountUser(
      id: id,
      email: email,
      name: name ?? this.name,
      home: home,
      permissions: permissions,
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class AccountUserNotifier extends StateNotifier<AccountUser> {
  final PhylumAccount _account;

  AccountUser get user => state;
  set user(AccountUser value) => state = value;

  AccountUserNotifier._(this._account, super.state) {
    stream.listen((user) {
      _account.persist(_persistKeyUser, jsonEncode(user.toJson()));
    });
  }

  factory AccountUserNotifier.fromUser(PhylumAccount account, AccountUser user) {
    account.persist(_persistKeyUser, jsonEncode(user.toJson()));
    return AccountUserNotifier._(account, user);
  }

  factory AccountUserNotifier.fromAccount(PhylumAccount account) {
    final user = AccountUser.fromJson(jsonDecode(account.getPersisted(_persistKeyUser)));
    return AccountUserNotifier._(account, user);
  }

  @override
  bool updateShouldNotify(AccountUser old, AccountUser current) {
    return old != current;
  }
}
