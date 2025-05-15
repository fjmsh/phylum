part of 'responses.dart';

class UserListResponse extends PhylumApiSuccessResponse {
  final Iterable<User> users;

  @override
  Future<void> process(PhylumAccount account) async {
    await account.db.batch((batch) {
      batch.insertAllOnConflictUpdate(account.db.users, users);
    });
  }

  UserListResponse({required this.users});

  factory UserListResponse.fromResponse(Map<String, dynamic> data) {
    final users = (data["users"] as List).cast<Map>().map((u) => User(
          id: u['id'],
          email: u['email'],
          displayName: u['display_name'],
        ));
    return UserListResponse(users: users);
  }
}
