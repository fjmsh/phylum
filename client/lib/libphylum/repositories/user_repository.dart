import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/phylum_api_types.dart';
import 'package:phylum/libphylum/requests/users_list_request.dart';

class UserRepository {
  final PhylumAccount account;
  Map<String, User> _users = const {};
  Map<String, User> get users => _users;

  UserRepository({required this.account}) {
    account.db.users.select().get().then((users) => _users = Map.unmodifiable(Map.fromIterable(users, key: (u) => u.username)));
  }

  Future<ApiResult> refreshUserList() async {
    return account.apiClient.sendRequest(UsersListRequest(), callback: (request, response) async {
      if (response is PhylumApiSuccessResponse) {
        await processUserListResponse(response.data);
      }
    });
  }

  String getUserDisplayName(String username) {
    return _users[username]?.display ?? username;
  }

  Future processUserListResponse(Map<String, dynamic> data) async {
    final db = account.db;
    final users = (data["users"] as List).cast<Map>().map((u) => parseUserObject(u.cast<String, dynamic>()));
    await db.batch((batch) {
      batch.insertAllOnConflictUpdate(db.users, users);
    });
    _users = Map.unmodifiable(Map.fromIterable(users, key: (u) => u.username));
  }

  User parseUserObject(Map<String, dynamic> data) {
    return User(
      username: data['username'],
      display: data['display'],
    );
  }
}
