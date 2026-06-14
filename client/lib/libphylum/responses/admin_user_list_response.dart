import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/user_permission.dart';

import 'responses.dart';

class AdminUserListResponse extends PhylumApiSuccessResponse {
  final Iterable<UserDetails> users;

  AdminUserListResponse({required this.users});

  factory AdminUserListResponse.fromResponse(Map<String, dynamic> data) {
    final users = (data['users'] as List)
        .cast<Map>()
        .map((a) => UserDetails.fromMap(a.cast<String, dynamic>()));

    return AdminUserListResponse(users: users);
  }

  @override
  Future process(PhylumAccount account) async {}
}

class UserDetails {
  final int id;
  final String email;
  final String name;
  final List<UserPermission> permissions;
  final String? home;

  UserDetails({
    required this.id,
    required this.email,
    required this.name,
    required this.permissions,
    required this.home,
  });

  factory UserDetails.fromMap(Map<String, dynamic> data) {
    return UserDetails(
      id: data['id'],
      email: data['email'],
      name: data['name'],
      permissions: (data['permissions'] as List).cast<UserPermission>(),
      home: data['home'],
    );
  }

  UserDetails copyWith({List<UserPermission>? permissions}) {
    return UserDetails(
      id: id,
      email: email,
      name: name,
      permissions: permissions ?? this.permissions,
      home: home,
    );
  }
}
