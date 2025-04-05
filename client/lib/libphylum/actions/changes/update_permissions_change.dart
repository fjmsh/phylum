import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:offtheline/offtheline.dart';
import 'package:phylum/libphylum/db/db.dart';
import 'package:phylum/util/permissions.dart';

class UpdatePermissionsChange extends LocalChange<Resource> {
  @override
  final String objectId;
  final String username;
  final int permission;
  final DateTime timestamp;

  @override
  String get description => 'Updating Permissions';

  const UpdatePermissionsChange({
    required this.objectId,
    required this.username,
    required this.permission,
    required this.timestamp,
  });

  @override
  Resource? apply(Resource? data) {
    if (data == null) return null;
    var p = data.grants.parseGrantsMap();
    if (p.containsKey(username) && p[username] == permission) {
      return data;
    }
    if (permission == 0) {
      p.remove(username);
    } else if (p.isEmpty) {
      // Empty means const map, so we can't add to it
      p = {username: permission};
    } else {
      p[username] = permission;
    }
    final serialized = p.isEmpty ? null : json.encode(p);
    return data.copyWith(
      permissions: Value(serialized),
      modified: Value(timestamp),
    );
  }
}
