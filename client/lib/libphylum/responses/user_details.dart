import 'package:drift/drift.dart';
import 'package:phylum/libphylum/db/db.dart' show User;
import 'package:phylum/libphylum/phylum_account.dart';
import 'package:phylum/libphylum/user_permission.dart';

import 'responses.dart';

class UserDetails extends PhylumApiSuccessResponse {
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

  factory UserDetails.fromResponse(Map<String, dynamic> data) {
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

  @override
  Future process(PhylumAccount account) async {
    await account.db.users.insertOne(
      User(id: id, email: email, name: name),
      mode: InsertMode.insertOrReplace,
    );
  }
}
