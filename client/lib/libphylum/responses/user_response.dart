part of 'responses.dart';

class UserResponse extends PhylumApiSuccessResponse {
  final User user;

  @override
  Future<void> process(PhylumAccount account) async {
    await account.db.users.insertOnConflictUpdate(user);
    await account.userRepository.replaceRemoteData(user.id.toString(), user);
  }

  UserResponse({required this.user});

  factory UserResponse.fromResponse(Map<String, dynamic> data) {
    final user = User(
      id: data['id'],
      email: data['email'],
      displayName: data['display_name'],
    );
    return UserResponse(user: user);
  }
}
