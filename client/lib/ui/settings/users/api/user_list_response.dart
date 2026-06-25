part of '../user_list_controller.dart';

class _UserListResponse extends PhylumApiSuccessResponse {
  final Iterable<UserDetails> users;

  _UserListResponse({required this.users});

  factory _UserListResponse.fromResponse(Map<String, dynamic> data) {
    final users = (data['users'] as List).cast<Map>().map(
      (a) => UserDetails.fromResponse(a.cast<String, dynamic>()),
    );

    return _UserListResponse(users: users);
  }

  @override
  Future process(PhylumAccount account) async {}
}
