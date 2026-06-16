import 'package:phylum/libphylum/phylum_account.dart';

import 'responses.dart';
import 'user_details.dart';

class AdminUserListResponse extends PhylumApiSuccessResponse {
  final Iterable<UserDetails> users;

  AdminUserListResponse({required this.users});

  factory AdminUserListResponse.fromResponse(Map<String, dynamic> data) {
    final users = (data['users'] as List)
        .cast<Map>()
        .map((a) => UserDetails.fromResponse(a.cast<String, dynamic>()));

    return AdminUserListResponse(users: users);
  }

  @override
  Future process(PhylumAccount account) async {}
}
