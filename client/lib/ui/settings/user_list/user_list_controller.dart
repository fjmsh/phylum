import 'dart:async';

import 'package:drift/drift.dart' show TableOrViewStatements;
import 'package:flutter/material.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

class UserList {
  final List<User>? users;

  UserList({required this.users});
}

class UserListController extends StateNotifier<UserList> {
  String _filter = '';
  List<User>? _users;
  StreamSubscription? _subscription;

  UserListController(BuildContext context) : super(UserList(users: null)) {
    final account = context.read<PhylumAccount>();
    _subscription = account.db.users.select().watch().listen((users) {
      _users = users;
      refilter();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  set filter(String filter) {
    _filter = filter;
    refilter();
  }

  void refilter() {
    final query = _filter.toLowerCase();
    final results = _filter.isEmpty
        ? _users
        : _users
            ?.where((u) => u.email.contains(query) || u.name.contains(query))
            .toList(growable: false);
    state = UserList(users: results);
  }
}
