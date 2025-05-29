import 'dart:convert';

import 'package:state_notifier/state_notifier.dart';

import 'phylum_account.dart';

part 'permissions.dart';

const _persistKeyUser = 'user';

class LoggedInUser {
  final int id;
  final String email;
  final String name;
  final String home;
  final int permissions;

  LoggedInUser({
    required this.id,
    required this.email,
    required this.name,
    required this.home,
    required this.permissions,
  });

  bool hasPermission(UserPermission p) => permissions & p != 0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoggedInUser) return false;

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

  factory LoggedInUser.fromJson(Map<String, dynamic> map) {
    return LoggedInUser(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      home: map['home'],
      permissions: map['permissions'],
    );
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}

class LoggedInUserNotifier extends StateNotifier<LoggedInUser> {
  final PhylumAccount _account;

  LoggedInUser get user => state;
  set user(LoggedInUser value) => state = value;

  LoggedInUserNotifier._(this._account, super.state) {
    stream.listen((user) {
      _account.persist(_persistKeyUser, jsonEncode(user.toJson()));
    });
  }

  factory LoggedInUserNotifier.fromUser(PhylumAccount account, LoggedInUser user) {
    account.persist(_persistKeyUser, jsonEncode(user.toJson()));
    return LoggedInUserNotifier._(account, user);
  }

  factory LoggedInUserNotifier.fromAccount(PhylumAccount account) {
    final user = LoggedInUser.fromJson(jsonDecode(account.getPersisted(_persistKeyUser)));
    return LoggedInUserNotifier._(account, user);
  }

  @override
  bool updateShouldNotify(LoggedInUser old, LoggedInUser current) {
    return old != current;
  }
}
