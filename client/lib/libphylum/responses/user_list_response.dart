part of 'responses.dart';

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
          username: u['username'],
          display: u['display'],
        ));
    return UserListResponse(users: users);
  }
}
