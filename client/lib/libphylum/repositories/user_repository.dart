import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/parsers/parsers.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/users_list_request.dart';

class UserRepository {
  final PhylumAccount account;
  Map<String, User> _users = const {};
  Map<String, User> get users => _users;

  UserRepository({required this.account});

  Future<void> initialize() async {
    refresh();
    await account.db.users
        .select()
        .get()
        .then((users) => _users = Map.unmodifiable(Map.fromIterable(users, key: (u) => u.username)));
  }

  Future<ApiResult> refresh() async {
    return account.apiClient.sendRequest(
        UsersListRequest(), (request, response) => parseJsonMapResponse(response, UserListResponse.fromResponse),
        callback: (request, response) async {
      if (response is UserListResponse) {
        _users = Map.unmodifiable(Map.fromIterable(response.users, key: (u) => u.username));
      }
    });
  }

  String getUserDisplayName(String username) {
    return _users[username]?.display ?? username;
  }
}

class UserListResponse extends PhylumApiSuccessResponse {
  final Iterable<User> users;

  @override
  Iterable<(Type, String)> get updatedObjects => const [];

  @override
  Future<void> process(PhylumAccount account) async {
    await account.db.batch((batch) {
      batch.insertAllOnConflictUpdate(account.db.users, users);
    });
  }

  UserListResponse({required this.users});

  factory UserListResponse.fromResponse(Map<String, dynamic> data) {
    final users = (data["users"] as List).cast<Map>().map((u) => User(
          username: data['username'],
          display: data['display'],
        ));
    return UserListResponse(users: users);
  }
}
