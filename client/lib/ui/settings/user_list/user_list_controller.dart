import 'package:flutter/material.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/requests/admin_user_list_request.dart';
import 'package:phylum/libphylum/responses/admin_user_list_response.dart';
import 'package:phylum/libphylum/user_permission.dart';
import 'package:provider/provider.dart';
import 'package:state_notifier/state_notifier.dart';

class UserListState {
  final bool loading;
  final String? error;
  final List<UserDetails>? users;

  const UserListState({
    this.loading = false,
    this.error,
    this.users,
  });
}

class UserListController extends StateNotifier<UserListState> {
  late final ApiClient<PhylumAccount> _apiClient;
  String _filter = '';
  List<UserDetails>? _users;

  UserListController(BuildContext context) : super(const UserListState()) {
    _apiClient = context.read<PhylumAccount>().apiClient;
  }

  void fetch() async {
    if (state.loading) return;
    final result = await _apiClient.sendRequest(AdminUserListRequest());
    if (result is AdminUserListResponse) {
      _users = result.users.toList(growable: false);
      refilter();
    } else {
      state = UserListState(error: result.description);
    }
  }

  void maybeFetch() {
    if (state.users == null) {
      fetch();
    }
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
            ?.where((u) =>
                u.email.contains(query) ||
                u.name.contains(query) ||
                u.id.toString().startsWith(query))
            .toList(growable: false);
    state = UserListState(users: results);
  }

  Future<String?> updatePermissions(
      UserDetails user, List<UserPermission> permissions) async {
    // TODO: Send request and update local model;
    return null;
  }
}
